terraform {
  backend "s3" {
    # Replace with the bucket created by infra/global/state-bootstrap.
    # This is the state bucket region, not necessarily the workload region.
    bucket       = "PLACEHOLDER-terraform-state-bucket"
    key          = "infra/envs/dev/ca-central-1/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
