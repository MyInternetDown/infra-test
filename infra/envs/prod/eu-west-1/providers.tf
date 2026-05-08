provider "aws" {
  region = var.settings.region

  default_tags {
    tags = local.provider_tags
  }
}
