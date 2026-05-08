output "secret_arns" {
  description = "Secrets Manager ARNs by logical name."
  value       = { for name, secret in aws_secretsmanager_secret.this : name => secret.arn }
}

output "ssm_parameter_names" {
  description = "SSM parameter names by logical name."
  value       = { for name, parameter in aws_ssm_parameter.this : name => parameter.name }
}
