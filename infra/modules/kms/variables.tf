variable "name_prefix" {
  description = "Prefix used for KMS aliases."
  type        = string
}

variable "keys" {
  description = "KMS keys to create for this stack."
  type = map(object({
    description             = string
    deletion_window_in_days = optional(number, 30)
    enable_key_rotation     = optional(bool, true)
    service_principals      = optional(list(string), [])
  }))
}

variable "tags" {
  description = "Tags applied to all KMS resources."
  type        = map(string)
  default     = {}
}
