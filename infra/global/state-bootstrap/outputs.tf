output "state_bucket_name" {
  description = "S3 bucket for Terraform state."
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_region" {
  description = "Region where the Terraform state bucket lives."
  value       = var.state_bucket_region
}

output "state_kms_key_arn" {
  description = "KMS key ARN used for Terraform state encryption."
  value       = aws_kms_key.state.arn
}
