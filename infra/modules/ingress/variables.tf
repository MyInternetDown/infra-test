variable "name" {
  description = "Name prefix for ingress resources."
  type        = string
}

variable "domain_name" {
  description = "Regional domain, for example ca-central-1.prod.example.com."
  type        = string
}

variable "hosted_zone_name" {
  description = "Route 53 public hosted zone name, for example example.com."
  type        = string
}

variable "create_certificate" {
  description = "Create a DNS-validated ACM certificate in this region for ALB ingress."
  type        = bool
  default     = true
}

variable "dns_alias_records" {
  description = "Optional Route 53 aliases to an already-created ALB. AWS Load Balancer Controller users usually add these after the ALB exists or via ExternalDNS."
  type = map(object({
    name         = string
    alb_dns_name = string
    alb_zone_id  = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to ingress resources."
  type        = map(string)
  default     = {}
}
