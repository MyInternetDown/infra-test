locals {
  name_prefix = lower(replace("${var.platform_name}-${var.environment}-${var.region}", "_", "-"))

  common_tags = merge(var.tags, {
    Platform    = var.platform_name
    Environment = var.environment
    Region      = var.region
    ManagedBy   = "terraform"
    Stack       = "regional-platform"
  })

  default_buckets = {
    app-data = {
      force_destroy           = var.environment == "dev"
      versioning_enabled      = true
      lifecycle_rules_enabled = true
    }
    audit-logs = {
      force_destroy           = false
      versioning_enabled      = true
      lifecycle_rules_enabled = true
    }
  }

  secret_metadata = {
    for name, description in var.secret_names : name => {
      description             = description
      recovery_window_in_days = var.environment == "dev" ? 7 : 30
    }
  }
}

module "kms" {
  source = "../../modules/kms"

  name_prefix = local.name_prefix
  keys = {
    eks = {
      description = "Encrypt EKS Kubernetes secrets for ${local.name_prefix}"
    }
    rds = {
      description = "Encrypt RDS PostgreSQL storage and managed credentials for ${local.name_prefix}"
    }
    s3 = {
      description = "Encrypt application S3 buckets for ${local.name_prefix}"
    }
    secrets = {
      description = "Encrypt Secrets Manager and SSM data for ${local.name_prefix}"
    }
    logs = {
      description = "Encrypt CloudWatch logs and alarm notifications for ${local.name_prefix}"
      service_principals = [
        "logs.${var.region}.amazonaws.com",
        "sns.amazonaws.com"
      ]
    }
    graph = {
      description = "Encrypt graph database storage for ${local.name_prefix}"
    }
  }
  tags = local.common_tags
}

module "networking" {
  source = "../../modules/networking"

  name                  = local.name_prefix
  vpc_cidr              = var.vpc_cidr
  azs                   = var.azs
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  enable_nat_gateway    = var.enable_nat_gateway
  single_nat_gateway    = var.single_nat_gateway
  enable_vpc_endpoints  = var.enable_vpc_endpoints
  tags                  = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  name                         = "${local.name_prefix}-eks"
  kubernetes_version           = var.kubernetes_version
  private_subnet_ids           = module.networking.private_subnet_ids
  endpoint_public_access       = var.eks_endpoint_public_access
  endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs
  kms_key_arn                  = module.kms.key_arns["eks"]
  node_groups                  = var.node_groups
  tags                         = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name                       = local.name_prefix
  vpc_id                     = module.networking.vpc_id
  allowed_ingress_cidrs      = var.allowed_ingress_cidrs
  workload_security_group_id = module.eks.cluster_security_group_id
  tags                       = local.common_tags
}

module "rds_postgres" {
  source = "../../modules/rds-postgres"

  name                         = local.name_prefix
  subnet_ids                   = module.networking.database_subnet_ids
  security_group_ids           = [module.security.rds_security_group_id]
  database_name                = var.database_name
  instance_class               = var.db_instance_class
  allocated_storage_gb         = var.db_allocated_storage_gb
  max_allocated_storage_gb     = var.db_max_allocated_storage_gb
  multi_az                     = var.db_multi_az
  backup_retention_days        = var.db_backup_retention_days
  deletion_protection          = var.db_deletion_protection
  skip_final_snapshot          = var.environment == "dev"
  kms_key_arn                  = module.kms.key_arns["rds"]
  performance_insights_enabled = var.environment != "dev"
  tags                         = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  name_prefix = local.name_prefix
  buckets     = merge(local.default_buckets, var.s3_buckets)
  kms_key_arn = module.kms.key_arns["s3"]
  tags        = local.common_tags
}

module "ingress" {
  source = "../../modules/ingress"

  name             = local.name_prefix
  domain_name      = var.domain_name
  hosted_zone_name = var.hosted_zone_name
  tags             = local.common_tags
}

module "secrets" {
  source = "../../modules/secrets"

  name_prefix    = local.name_prefix
  secrets        = local.secret_metadata
  ssm_parameters = var.ssm_parameters
  kms_key_arn    = module.kms.key_arns["secrets"]
  tags           = local.common_tags
}

module "graph_database" {
  source = "../../modules/neo4j"

  name                  = local.name_prefix
  enabled               = var.enable_graph_database
  mode                  = var.graph_database_mode
  subnet_ids            = module.networking.database_subnet_ids
  security_group_ids    = [module.security.graph_security_group_id]
  kms_key_arn           = module.kms.key_arns["graph"]
  instance_class        = var.graph_instance_class
  instance_count        = var.graph_instance_count
  backup_retention_days = var.environment == "prod" ? 14 : 7
  deletion_protection   = var.environment != "dev"
  skip_final_snapshot   = var.environment == "dev"
  tags                  = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix         = local.name_prefix
  oidc_provider_arn   = module.eks.oidc_provider_arn
  oidc_provider_url   = module.eks.oidc_provider_url
  workload_irsa_roles = var.workload_irsa_roles
  tags                = local.common_tags
}

module "observability" {
  source = "../../modules/observability"

  name                     = local.name_prefix
  log_group_names          = ["/aws/eks/${module.eks.cluster_name}/application"]
  log_retention_days       = var.log_retention_days
  rds_instance_id          = module.rds_postgres.instance_id
  kms_key_arn              = module.kms.key_arns["logs"]
  sns_email_endpoints      = var.alarm_email_endpoints
  monthly_budget_limit_usd = var.monthly_budget_limit_usd
  tags                     = local.common_tags
}
