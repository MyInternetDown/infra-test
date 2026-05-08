variable "name_prefix" {
  description = "Prefix used for bucket names."
  type        = string
}

variable "buckets" {
  description = "Application buckets to create."
  type = map(object({
    force_destroy           = optional(bool, false)
    versioning_enabled      = optional(bool, true)
    lifecycle_rules_enabled = optional(bool, true)
  }))
}

variable "kms_key_arn" {
  description = "KMS key ARN for bucket encryption."
  type        = string
}

variable "tags" {
  description = "Tags applied to buckets."
  type        = map(string)
  default     = {}
}
