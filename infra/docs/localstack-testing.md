# LocalStack Testing

## Can This Stack Run On LocalStack?

Partially. LocalStack is useful for fast Terraform smoke tests and developer
feedback, but it is not a production-equivalent AWS environment.

The default local root covers:

- VPC, subnets, route tables, and security groups
- KMS keys and aliases
- S3 bucket hardening
- Secrets Manager metadata and SSM parameters
- GitHub OIDC IAM role shape
- CloudWatch log groups and SNS alarm topic

The default local root does not cover:

- EKS control plane behavior, node groups, add-ons, or Kubernetes workloads
- production RDS PostgreSQL behavior, backups, performance insights, or failover
- Neptune or a real Neo4j deployment
- Route 53 public DNS delegation and ACM validation against real domains
- multi-region failover or regional data replication

## Commands

Start LocalStack:

```bash
make localstack-up
```

Run Terraform init, validate, and plan:

```bash
make localstack-smoke
```

If `make` is not installed:

```bash
./scripts/localstack-smoke.sh
```

Apply local resources:

```bash
APPLY=1 make localstack-smoke
```

If `make` is not installed:

```bash
APPLY=1 ./scripts/localstack-smoke.sh
```

Destroy local resources:

```bash
make localstack-destroy
```

Stop LocalStack:

```bash
make localstack-down
```

## RDS Experiment

The local root includes an optional RDS module attempt:

```bash
terraform -chdir=infra/tests/localstack plan -var enable_rds_smoke=true
```

Before using it, add `rds` to the `SERVICES` list in
`docker-compose.localstack.yml`.

Treat this as experimental. The production RDS module uses managed master
passwords, encryption, backups, deletion behavior, and optional Performance
Insights settings. Passing locally does not prove those production controls work
in AWS.

## Requirements

- Docker with Compose v2
- Terraform `>= 1.10.0`
- First-run network access to pull the pinned `localstack/localstack:4.14.0`
  image
- First-run network access for Terraform provider downloads

## Why A Separate Root?

The real environment roots model production infrastructure. The LocalStack root
is a smoke-test target that reuses modules where emulation is practical. Keeping
it separate prevents accidental changes that make the production roots easier to
emulate but less accurate for AWS.
