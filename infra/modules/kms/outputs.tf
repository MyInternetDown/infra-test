output "key_arns" {
  description = "KMS key ARNs by logical key name."
  value       = { for name, key in aws_kms_key.this : name => key.arn }
}

output "key_ids" {
  description = "KMS key IDs by logical key name."
  value       = { for name, key in aws_kms_key.this : name => key.key_id }
}
