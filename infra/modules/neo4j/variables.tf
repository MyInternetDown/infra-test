variable "name" {
  description = "Name prefix for graph database resources."
  type        = string
}

variable "enabled" {
  description = "Create graph database resources."
  type        = bool
  default     = false
}

variable "mode" {
  description = "Graph database mode. neptune is the managed AWS default; neo4j-self-managed is documented but intentionally not provisioned here."
  type        = string
  default     = "neptune"

  validation {
    condition     = contains(["neptune", "neo4j-self-managed"], var.mode)
    error_message = "mode must be either neptune or neo4j-self-managed."
  }
}

variable "subnet_ids" {
  description = "Private database subnet IDs."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Graph database security group IDs."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for graph database encryption."
  type        = string
}

variable "instance_class" {
  description = "Neptune instance class."
  type        = string
  default     = "db.t4g.medium"
}

variable "instance_count" {
  description = "Number of Neptune instances."
  type        = number
  default     = 1
}

variable "backup_retention_days" {
  description = "Neptune backup retention in days."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental graph database deletion."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy. Keep false outside ephemeral development."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to graph database resources."
  type        = map(string)
  default     = {}
}
