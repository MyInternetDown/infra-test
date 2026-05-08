variable "platform_name" {
  description = "Short platform name used in resource names."
  type        = string
}

variable "environment" {
  description = "Environment name: dev, staging, or prod."
  type        = string
}

variable "region" {
  description = "AWS region for this isolated regional stack."
  type        = string
}

variable "domain_name" {
  description = "Regional DNS name, for example ca-central-1.prod.example.com."
  type        = string
}

variable "hosted_zone_name" {
  description = "Public Route 53 hosted zone name, for example example.com."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for this region's VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones used by this regional stack."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public edge subnet CIDRs."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private EKS workload subnet CIDRs."
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "Private database subnet CIDRs."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Create NAT gateways for private subnet egress."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway. Suitable for low-cost dev, not production HA."
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Create common VPC endpoints for AWS APIs."
  type        = bool
  default     = true
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to reach public ALB/API entrypoints."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "eks_endpoint_public_access" {
  description = "Enable public Kubernetes API endpoint."
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint."
  type        = list(string)
  default     = []
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

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
}

variable "db_allocated_storage_gb" {
  description = "Initial RDS storage size."
  type        = number
}

variable "db_max_allocated_storage_gb" {
  description = "Maximum RDS autoscaled storage size."
  type        = number
}

variable "db_multi_az" {
  description = "Enable RDS Multi-AZ."
  type        = bool
}

variable "db_backup_retention_days" {
  description = "RDS automated backup retention."
  type        = number
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection."
  type        = bool
}

variable "s3_buckets" {
  description = "Additional application buckets. app-data and audit-logs are created by default."
  type = map(object({
    force_destroy           = optional(bool, false)
    versioning_enabled      = optional(bool, true)
    lifecycle_rules_enabled = optional(bool, true)
  }))
  default = {}
}

variable "secret_names" {
  description = "Application secret names to create as empty Secrets Manager metadata."
  type        = map(string)
  default     = {}
}

variable "ssm_parameters" {
  description = "Non-sensitive SSM parameters to create."
  type = map(object({
    description = string
    type        = optional(string, "String")
    value       = string
  }))
  default = {}
}

variable "workload_irsa_roles" {
  description = "IRSA roles for Kubernetes workloads."
  type = map(object({
    namespace       = string
    service_account = string
    policy_json     = string
  }))
  default = {}
}

variable "enable_graph_database" {
  description = "Create graph database resources."
  type        = bool
  default     = false
}

variable "graph_database_mode" {
  description = "Graph database mode: neptune or neo4j-self-managed."
  type        = string
  default     = "neptune"
}

variable "graph_instance_class" {
  description = "Neptune instance class when graph_database_mode is neptune."
  type        = string
  default     = "db.t4g.medium"
}

variable "graph_instance_count" {
  description = "Number of Neptune instances when graph_database_mode is neptune."
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch log retention for application log groups."
  type        = number
  default     = 30
}

variable "alarm_email_endpoints" {
  description = "Alarm email recipients."
  type        = list(string)
  default     = []
}

variable "monthly_budget_limit_usd" {
  description = "Optional monthly budget limit for this stack."
  type        = number
  default     = null
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
