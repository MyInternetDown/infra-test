# infra-test

Production-oriented AWS + Terraform infrastructure starter for a multi-service
platform using EKS, RDS PostgreSQL, S3, Route 53, KMS, Secrets Manager, CloudWatch,
and an optional managed graph database pattern.

The repository is structured around isolated environment and region roots. Dev
and staging start in `ca-central-1`; production includes separate regional roots
for `ca-central-1`, `us-east-1`, and `eu-west-1`. Each production region gets its
own VPC and EKS cluster. A region is not inside a cluster; the EKS cluster is a
regional AWS resource deployed into a regional VPC.

## Layout

```text
infra/
  modules/                    Reusable Terraform building blocks
    networking/               VPC, public/private/database subnets, NAT, endpoints
    eks/                      EKS cluster, managed nodes, OIDC provider, addons
    iam/                      IRSA roles and GitHub Actions OIDC role
    rds-postgres/             Private RDS PostgreSQL with managed password
    s3/                       Private encrypted application buckets
    security/                 ALB, database, and graph security groups
    ingress/                  ACM certificate and DNS alias helpers
    observability/            CloudWatch logs, alarms, SNS, budget
    kms/                      Regional KMS keys
    secrets/                  Secret metadata and non-sensitive SSM parameters
    neo4j/                    Managed AWS Neptune option for graph workloads
  stacks/regional-platform/   Composition layer used by every env/region root
  envs/
    dev/ca-central-1/
    staging/ca-central-1/
    prod/ca-central-1/
    prod/us-east-1/
    prod/eu-west-1/
    prod/_template/
  global/
    state-bootstrap/          First-run S3 state bucket with native S3 locking
    dns/                      Shared Route 53 zone/delegation scaffolding
    iam/                      GitHub Actions OIDC deploy role scaffolding
  tests/localstack/           LocalStack smoke-test root for supported modules
  docs/                       Architecture, runbooks, and checklists
  pipelines/                  Notes for GitHub Actions examples
.github/workflows/            PR validation, promotion, new-region plan examples
```

## Deployment Flow

1. Run `infra/global/state-bootstrap` locally once to create the encrypted,
   versioned Terraform state bucket.
2. Replace `PLACEHOLDER-terraform-state-bucket` in backend files, or pass
   `-backend-config="bucket=..."` from CI.
3. Apply `infra/global/dns` if this repo should own hosted zone or delegation
   records.
4. Apply `infra/global/iam` after replacing the GitHub repo placeholder and
   attaching a reviewed deploy policy.
5. Promote infrastructure through dev, staging, and production regional roots.

Each root uses an S3 backend with `use_lockfile = true`, so Terraform 1.10 or
newer is required for native S3 state locking.

## Key Docs

- [Architecture](./infra/docs/architecture.md)
- [Add production region runbook](./infra/docs/add-production-region-runbook.md)
- [Security checklist](./infra/docs/security-checklist.md)
- [Reliability checklist](./infra/docs/reliability-checklist.md)
- [Cost control checklist](./infra/docs/cost-control-checklist.md)
- [LocalStack testing](./infra/docs/localstack-testing.md)
- [Risks and decisions](./infra/docs/risks-and-decisions.md)

## LocalStack Smoke Test

The repo includes a LocalStack smoke-test path for the module surfaces that are
reasonable to emulate locally:

```bash
make localstack-smoke
```

If `make` is not installed, run the script directly:

```bash
./scripts/localstack-smoke.sh
```

That runs Terraform `init`, `validate`, and `plan` against
`infra/tests/localstack`. To apply the local resources, run:

```bash
APPLY=1 make localstack-smoke
```

Or without `make`:

```bash
APPLY=1 ./scripts/localstack-smoke.sh
```

This does not replace AWS validation for EKS, production RDS behavior, Neptune,
or multi-region failover.

## Important Placeholders

Replace these before any real apply:

- `PLACEHOLDER-terraform-state-bucket`
- `PLACEHOLDER-company-product-platform-terraform-state`
- `example.com`
- `devops@example.com`
- `PLACEHOLDER-ORG/PLACEHOLDER-REPO`
- EKS endpoint allow-list CIDRs such as `203.0.113.0/24`

Do not put secret values into `terraform.tfvars`. The scaffold creates secret
metadata only; secret values should be inserted through a controlled secret
rotation or release workflow.
