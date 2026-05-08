provider "aws" {
  region = var.state_bucket_region

  default_tags {
    tags = merge(var.tags, {
      ManagedBy = "terraform"
      Scope     = "state-bootstrap"
    })
  }
}
