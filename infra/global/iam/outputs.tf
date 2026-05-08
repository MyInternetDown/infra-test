output "github_deploy_role_arn" {
  description = "GitHub Actions deploy role ARN."
  value       = module.github_actions.github_deploy_role_arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN."
  value       = module.github_actions.github_oidc_provider_arn
}
