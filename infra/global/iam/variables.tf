variable "aws_region" {
  description = "AWS region used for IAM API calls."
  type        = string
  default     = "ca-central-1"
}

variable "name_prefix" {
  description = "Name prefix for global IAM resources."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in owner/name form."
  type        = string
}

variable "github_allowed_refs" {
  description = "Git refs allowed to assume the deploy role."
  type        = list(string)
  default     = ["refs/heads/main"]
}

variable "github_deploy_policy_json" {
  description = "Least-privilege deploy policy JSON. Leave null until the team has reviewed the exact permissions."
  type        = string
  default     = null
}

variable "github_attach_deploy_policy" {
  description = "Attach github_deploy_policy_json to the GitHub deploy role after review."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
