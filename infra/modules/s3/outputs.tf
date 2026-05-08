output "bucket_names" {
  description = "Bucket names by logical key."
  value       = { for name, bucket in aws_s3_bucket.this : name => bucket.bucket }
}

output "bucket_arns" {
  description = "Bucket ARNs by logical key."
  value       = { for name, bucket in aws_s3_bucket.this : name => bucket.arn }
}
