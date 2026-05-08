name_prefix       = "product-platform"
github_repository = "PLACEHOLDER-ORG/PLACEHOLDER-REPO"

github_allowed_refs = [
  "refs/heads/main"
]

# Intentionally null by default: do not attach AdministratorAccess casually.
# Add a reviewed, least-privilege policy that permits only this repo's Terraform
# state access and the AWS services managed by these modules.
github_deploy_policy_json   = null
github_attach_deploy_policy = false

tags = {
  Owner      = "platform-team"
  CostCenter = "shared"
}
