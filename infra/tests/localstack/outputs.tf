output "vpc_id" {
  description = "LocalStack VPC ID."
  value       = module.networking.vpc_id
}

output "bucket_names" {
  description = "LocalStack smoke-test S3 bucket names."
  value       = module.s3.bucket_names
}

output "secret_arns" {
  description = "LocalStack smoke-test secret ARNs."
  value       = module.secrets.secret_arns
}

output "github_deploy_role_arn" {
  description = "LocalStack smoke-test GitHub deploy role ARN."
  value       = module.github_iam.github_deploy_role_arn
}

output "alarm_topic_arn" {
  description = "LocalStack smoke-test SNS alarm topic ARN."
  value       = module.observability.alarm_topic_arn
}

output "rds_endpoint" {
  description = "Experimental LocalStack RDS endpoint when enable_rds_smoke is true."
  value       = var.enable_rds_smoke ? module.rds_postgres[0].endpoint : null
}
