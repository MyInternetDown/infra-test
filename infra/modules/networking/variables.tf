variable "name" {
  description = "Name prefix for regional networking resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for this regional VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones to use in this region."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public edge subnets. These host ALBs and NAT gateways only."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private workload subnets. EKS nodes and pods run here."
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "CIDRs for private database subnets. These do not receive a default route to the internet."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Create NAT gateways for private subnet egress. Disable only when VPC endpoints or private connectivity cover all egress needs."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway to reduce cost. Keep false for production high availability."
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Create common AWS VPC endpoints to reduce NAT dependency and keep AWS API traffic private."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all networking resources."
  type        = map(string)
  default     = {}
}

locals {
  subnet_count_valid = length(var.azs) == length(var.public_subnet_cidrs) && length(var.azs) == length(var.private_subnet_cidrs) && length(var.azs) == length(var.database_subnet_cidrs)
}

check "matching_subnet_counts" {
  assert {
    condition     = local.subnet_count_valid
    error_message = "azs, public_subnet_cidrs, private_subnet_cidrs, and database_subnet_cidrs must have the same length."
  }
}
