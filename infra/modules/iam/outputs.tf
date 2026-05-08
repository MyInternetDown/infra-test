output "irsa_role_arns" {
  description = "IRSA role ARNs by logical name."
  value       = { for name, role in aws_iam_role.irsa : name => role.arn }
}

output "github_deploy_role_arn" {
  description = "GitHub Actions deploy role ARN, null when disabled."
  value       = var.github_oidc_enabled ? aws_iam_role.github_deploy[0].arn : null
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN, null when disabled."
  value       = var.github_oidc_enabled ? aws_iam_openid_connect_provider.github[0].arn : null
}
