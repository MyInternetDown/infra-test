module "kms" {
  source = "../../modules/kms"

  name_prefix = var.name_prefix
  keys = {
    s3 = {
      description = "LocalStack smoke-test S3 encryption key"
    }
    secrets = {
      description = "LocalStack smoke-test Secrets Manager and SSM encryption key"
    }
    logs = {
      description = "LocalStack smoke-test CloudWatch Logs and SNS encryption key"
      service_principals = [
        "logs.${var.aws_region}.amazonaws.com",
        "sns.amazonaws.com"
      ]
    }
    rds = {
      description = "LocalStack smoke-test RDS encryption key"
    }
  }

  tags = local.common_tags
}

module "networking" {
  source = "../../modules/networking"

  name                  = var.name_prefix
  vpc_cidr              = "10.250.0.0/16"
  azs                   = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnet_cidrs   = ["10.250.0.0/24", "10.250.1.0/24"]
  private_subnet_cidrs  = ["10.250.10.0/24", "10.250.11.0/24"]
  database_subnet_cidrs = ["10.250.20.0/24", "10.250.21.0/24"]
  enable_nat_gateway    = false
  enable_vpc_endpoints  = false
  tags                  = local.common_tags
}

resource "aws_security_group" "workloads" {
  name        = "${var.name_prefix}-workloads"
  description = "Synthetic workload security group for LocalStack smoke tests."
  vpc_id      = module.networking.vpc_id

  egress {
    description = "Outbound from synthetic workloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-workloads"
  })
}

module "security" {
  source = "../../modules/security"

  name                       = var.name_prefix
  vpc_id                     = module.networking.vpc_id
  allowed_ingress_cidrs      = ["127.0.0.1/32"]
  workload_security_group_id = aws_security_group.workloads.id
  tags                       = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  name_prefix = var.name_prefix
  kms_key_arn = module.kms.key_arns["s3"]
  buckets = {
    app-data = {
      force_destroy           = true
      versioning_enabled      = true
      lifecycle_rules_enabled = true
    }
    audit-logs = {
      force_destroy           = true
      versioning_enabled      = true
      lifecycle_rules_enabled = true
    }
  }

  tags = local.common_tags
}

module "secrets" {
  source = "../../modules/secrets"

  name_prefix = var.name_prefix
  kms_key_arn = module.kms.key_arns["secrets"]

  secrets = {
    "app/runtime" = {
      description             = "LocalStack smoke-test secret metadata only."
      recovery_window_in_days = 0
    }
  }

  ssm_parameters = {
    "app/environment" = {
      description = "LocalStack smoke-test environment marker."
      value       = "localstack"
    }
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "github_deploy_smoke" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = concat(
      values(module.s3.bucket_arns),
      [for arn in values(module.s3.bucket_arns) : "${arn}/*"]
    )
  }
}

module "github_iam" {
  source = "../../modules/iam"

  name_prefix                 = var.name_prefix
  github_oidc_enabled         = true
  github_repository           = "example/infra-test"
  github_allowed_refs         = ["refs/heads/main"]
  github_attach_deploy_policy = true
  github_deploy_policy_json   = data.aws_iam_policy_document.github_deploy_smoke.json
  tags                        = local.common_tags
}

module "observability" {
  source = "../../modules/observability"

  name                = var.name_prefix
  log_group_names     = ["/localstack/${var.name_prefix}/application"]
  log_retention_days  = 7
  kms_key_arn         = module.kms.key_arns["logs"]
  sns_email_endpoints = []
  tags                = local.common_tags
}

module "rds_postgres" {
  count  = var.enable_rds_smoke ? 1 : 0
  source = "../../modules/rds-postgres"

  name                         = var.name_prefix
  subnet_ids                   = module.networking.database_subnet_ids
  security_group_ids           = [module.security.rds_security_group_id]
  database_name                = "app"
  instance_class               = "db.t3.micro"
  allocated_storage_gb         = 20
  max_allocated_storage_gb     = 100
  multi_az                     = false
  backup_retention_days        = 1
  deletion_protection          = false
  skip_final_snapshot          = true
  kms_key_arn                  = module.kms.key_arns["rds"]
  performance_insights_enabled = false
  tags                         = local.common_tags
}
