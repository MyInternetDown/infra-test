variable "name" {
  description = "Name prefix for observability resources."
  type        = string
}

variable "log_group_names" {
  description = "Application log groups to create."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}

variable "rds_instance_id" {
  description = "RDS instance ID for baseline database alarms."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt CloudWatch log groups and SNS alarm topic."
  type        = string
}

variable "sns_email_endpoints" {
  description = "Email endpoints for alarm notifications. Confirm subscriptions after creation."
  type        = list(string)
  default     = []
}

variable "monthly_budget_limit_usd" {
  description = "Optional account budget limit for this stack. Null disables budget creation."
  type        = number
  default     = null
}

variable "tags" {
  description = "Tags applied to observability resources."
  type        = map(string)
  default     = {}
}
