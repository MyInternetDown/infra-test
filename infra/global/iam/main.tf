module "github_actions" {
  source = "../../modules/iam"

  name_prefix                 = var.name_prefix
  github_oidc_enabled         = true
  github_repository           = var.github_repository
  github_allowed_refs         = var.github_allowed_refs
  github_attach_deploy_policy = var.github_attach_deploy_policy
  github_deploy_policy_json   = var.github_deploy_policy_json
  tags                        = var.tags
}
