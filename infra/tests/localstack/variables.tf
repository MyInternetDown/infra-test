variable "aws_region" {
  description = "LocalStack test region."
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "LocalStack edge endpoint."
  type        = string
  default     = "http://127.0.0.1:4566"
}

variable "name_prefix" {
  description = "Prefix used for local smoke-test resources."
  type        = string
  default     = "infra-test-local"
}

variable "enable_rds_smoke" {
  description = "Attempt the RDS module against LocalStack. This is experimental and disabled by default."
  type        = bool
  default     = false
}
