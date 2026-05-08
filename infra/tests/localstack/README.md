# LocalStack Terraform Smoke Test

This root is for local Terraform feedback against LocalStack. It intentionally
does not try to run the full regional platform stack because EKS, RDS, and
Neptune emulation is not equivalent to AWS production control planes.

The default smoke test covers:

- VPC, subnets, route tables, and security groups
- KMS keys and aliases
- private encrypted S3 buckets
- Secrets Manager metadata and SSM parameters
- GitHub OIDC IAM role shape
- CloudWatch log groups and SNS alarm topic

RDS can be attempted with `-var enable_rds_smoke=true`, but that path is
experimental because LocalStack RDS support may not match the production module's
managed password, encryption, backup, and snapshot behavior. Add `rds` back to
the `SERVICES` list in `docker-compose.localstack.yml` before trying that path.

## Run

```bash
make localstack-smoke
```

By default the smoke script runs `init`, `validate`, and `plan`. To apply:

```bash
APPLY=1 make localstack-smoke
```

To clean up applied local resources:

```bash
make localstack-destroy
make localstack-down
```

## Requirements

- Docker with Compose v2
- Terraform `>= 1.10.0`
- Network access the first time Docker pulls the pinned LocalStack image and
  Terraform downloads providers
