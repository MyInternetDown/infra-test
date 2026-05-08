variable "aws_region" {
  description = "AWS region used by the Route 53 API."
  type        = string
  default     = "ca-central-1"
}

variable "root_domain_name" {
  description = "Root public DNS zone, for example example.com."
  type        = string
}

variable "create_public_zone" {
  description = "Create the public hosted zone. Set false when the zone already exists outside this repo."
  type        = bool
  default     = false
}

variable "delegated_subdomains" {
  description = "Optional NS delegation records for environment or regional subdomains."
  type = map(object({
    name_servers = list(string)
    ttl          = optional(number, 300)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to DNS resources."
  type        = map(string)
  default     = {}
}
