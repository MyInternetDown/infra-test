terraform {
  backend "s3" {
    bucket       = "PLACEHOLDER-terraform-state-bucket"
    key          = "infra/global/iam/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
