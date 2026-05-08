variable "name_prefix" {
  description = "Prefix for Secrets Manager and SSM parameter names."
  type        = string
}

variable "secrets" {
  description = "Secrets Manager secret metadata. Do not put secret values in Terraform."
  type = map(object({
    description             = string
    recovery_window_in_days = optional(number, 30)
  }))
  default = {}
}

variable "ssm_parameters" {
  description = "Non-sensitive SSM parameters. Secret values should be inserted out of band."
  type = map(object({
    description = string
    type        = optional(string, "String")
    value       = string
  }))
  default = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for secrets."
  type        = string
}

variable "tags" {
  description = "Tags applied to secrets resources."
  type        = map(string)
  default     = {}
}
