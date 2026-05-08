output "instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.id
}

output "endpoint" {
  description = "PostgreSQL endpoint including port."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "PostgreSQL hostname."
  value       = aws_db_instance.this.address
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for the RDS-managed master password."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}
