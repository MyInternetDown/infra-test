variable "name_prefix" {
  description = "Name prefix for IAM resources."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA roles."
  type        = string
  default     = null
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL for IRSA roles."
  type        = string
  default     = null
}

variable "workload_irsa_roles" {
  description = "IRSA roles for Kubernetes service accounts. policy_json must be least-privilege and workload-specific."
  type = map(object({
    namespace       = string
    service_account = string
    policy_json     = string
  }))
  default = {}
}

variable "github_oidc_enabled" {
  description = "Create GitHub Actions OIDC provider and deploy role."
  type        = bool
  default     = false
}

variable "github_repository" {
  description = "GitHub repository in owner/name form allowed to assume the deploy role."
  type        = string
  default     = null
}

variable "github_allowed_refs" {
  description = "Allowed Git refs for the GitHub deploy role, for example refs/heads/main."
  type        = list(string)
  default     = ["refs/heads/main"]
}

variable "github_deploy_policy_json" {
  description = "Policy JSON attached to the GitHub deploy role. Keep scoped to this platform, state bucket, and environments."
  type        = string
  default     = null
}

variable "github_attach_deploy_policy" {
  description = "Attach github_deploy_policy_json to the GitHub deploy role. Use this instead of deriving count from computed policy JSON."
  type        = bool
  default     = false
}

variable "github_oidc_thumbprints" {
  description = "Thumbprints required by the IAM API. AWS ignores the GitHub thumbprint during auth but Terraform still requires a value."
  type        = list(string)
  default     = ["ffffffffffffffffffffffffffffffffffffffff"]
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
