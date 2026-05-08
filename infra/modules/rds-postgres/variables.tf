variable "name" {
  description = "Name prefix for PostgreSQL resources."
  type        = string
}

variable "subnet_ids" {
  description = "Private database subnet IDs."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups allowed to reach PostgreSQL."
  type        = list(string)
}

variable "database_name" {
  description = "Initial database name."
  type        = string
}

variable "master_username" {
  description = "Master username. The password is managed by RDS in Secrets Manager."
  type        = string
  default     = "app_admin"
}

variable "engine_version" {
  description = "Optional PostgreSQL engine version. Leave null to let AWS choose the current default for the engine family."
  type        = string
  default     = null
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "allocated_storage_gb" {
  description = "Initial allocated storage in GiB."
  type        = number
}

variable "max_allocated_storage_gb" {
  description = "Maximum autoscaled storage in GiB."
  type        = number
}

variable "multi_az" {
  description = "Enable synchronous standby in another AZ. Recommended for production."
  type        = bool
}

variable "backup_retention_days" {
  description = "Automated backup retention in days."
  type        = number
}

variable "deletion_protection" {
  description = "Prevent accidental database deletion."
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy. Keep false outside ephemeral development."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for storage encryption and managed master password secret."
  type        = string
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to RDS resources."
  type        = map(string)
  default     = {}
}
