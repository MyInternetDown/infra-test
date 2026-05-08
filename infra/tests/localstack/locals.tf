locals {
  common_tags = {
    Environment = "localstack"
    ManagedBy   = "terraform"
    Purpose     = "local-smoke-test"
  }
}
