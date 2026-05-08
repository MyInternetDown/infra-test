# Infrastructure README

This directory contains the Terraform platform scaffold. The design goal is to
make environment and region roots thin while keeping reusable infrastructure in
modules and the regional composition stack.

## First Run

```bash
cd infra/global/state-bootstrap
terraform init
terraform plan
terraform apply
```

After the state bucket exists, initialize other roots with the real backend
bucket:

```bash
cd infra/envs/dev/ca-central-1
terraform init \
  -backend-config="bucket=<state-bucket-name>" \
  -backend-config="region=ca-central-1"
terraform plan
```

## Promotion

Use the same module code in every environment:

```text
dev/ca-central-1 -> staging/ca-central-1 -> prod/<region>
```

Promotion should be a pipeline action with reviewed plans and GitHub Environment
approval before apply. See `.github/workflows/terraform-promote.yml`.

## Production Regions

Production regions are independent failure domains. Each region has:

- its own Terraform state key
- its own VPC
- its own private EKS cluster and node groups
- its own private RDS PostgreSQL instance
- its own buckets, KMS keys, alarms, and optional graph database resources

Do not try to stretch one VPC or EKS cluster across regions.

## Production Application Deployment

Infrastructure promotion and application rollout are separate concerns. Use the
Terraform workflows to manage AWS infrastructure, then use
`scripts/prod-progressive-deploy.sh` for region-by-region Kubernetes application
rollouts. See `infra/docs/prod-progressive-deployment.md`.

## LocalStack Testing

For fast local feedback on supported AWS APIs, use:

```bash
make localstack-smoke
```

If `make` is not installed:

```bash
./scripts/localstack-smoke.sh
```

The LocalStack root lives at `infra/tests/localstack` and covers networking,
security groups, KMS, S3, Secrets Manager, SSM, IAM OIDC shape, CloudWatch Logs,
and SNS. It intentionally does not run the full EKS/RDS/Neptune production stack.
See `infra/docs/localstack-testing.md` for details.
