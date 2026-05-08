variable "name" {
  description = "Name prefix for security groups."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created."
  type        = string
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to reach public edge resources."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "workload_security_group_id" {
  description = "Security group ID used by EKS workloads that need database access."
  type        = string
}

variable "tags" {
  description = "Tags applied to security resources."
  type        = map(string)
  default     = {}
}
