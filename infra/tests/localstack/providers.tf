provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    acm            = var.localstack_endpoint
    cloudwatch     = var.localstack_endpoint
    ec2            = var.localstack_endpoint
    iam            = var.localstack_endpoint
    kms            = var.localstack_endpoint
    logs           = var.localstack_endpoint
    rds            = var.localstack_endpoint
    route53        = var.localstack_endpoint
    s3             = var.localstack_endpoint
    secretsmanager = var.localstack_endpoint
    sns            = var.localstack_endpoint
    ssm            = var.localstack_endpoint
    sts            = var.localstack_endpoint
  }

  default_tags {
    tags = local.common_tags
  }
}
