terraform {
  backend "s3" {
    bucket       = "PLACEHOLDER-terraform-state-bucket"
    key          = "infra/envs/prod/eu-west-1/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
