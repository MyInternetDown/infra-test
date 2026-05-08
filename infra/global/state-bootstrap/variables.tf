variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state."
  type        = string
}

variable "state_bucket_region" {
  description = "AWS region for the Terraform state bucket."
  type        = string
  default     = "ca-central-1"
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the state bucket. Keep false for real environments."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to bootstrap resources."
  type        = map(string)
  default     = {}
}
