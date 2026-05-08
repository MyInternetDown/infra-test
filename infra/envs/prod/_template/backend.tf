terraform {
  backend "s3" {
    bucket       = "PLACEHOLDER-terraform-state-bucket"
    key          = "infra/envs/prod/PLACEHOLDER-REGION/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
