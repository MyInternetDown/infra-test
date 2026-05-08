variable "name" {
  description = "EKS cluster name."
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Keep this explicit and upgrade deliberately."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS control plane ENIs and managed node groups."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Enable public Kubernetes API endpoint. Prefer false or a narrow CIDR list for production."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt Kubernetes secrets."
  type        = string
  default     = null
}

variable "enabled_cluster_log_types" {
  description = "EKS control plane log types sent to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "node_groups" {
  description = "Managed node groups keyed by logical name."
  type = map(object({
    instance_types = list(string)
    min_size       = number
    desired_size   = number
    max_size       = number
    disk_size      = optional(number, 50)
    capacity_type  = optional(string, "ON_DEMAND")
    ami_type       = optional(string, "AL2_x86_64")
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  }))
}

variable "tags" {
  description = "Tags applied to EKS resources."
  type        = map(string)
  default     = {}
}
