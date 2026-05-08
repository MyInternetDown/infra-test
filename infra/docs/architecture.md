# Architecture

## Overview

The platform is split by environment and region. Dev and staging start in one
region each. Production is multi-region, but each production region is isolated:
separate Terraform state, VPC, EKS cluster, databases, KMS keys, S3 buckets, and
alarms.

Clients reach applications through controlled public entry points such as Route
53 records, an internet-facing ALB managed by AWS Load Balancer Controller, or
API Gateway when request validation, throttling, auth, or a stable API front door
is needed. Workloads and databases stay private.

## ASCII Diagram

```text
Users / Clients
      |
      v
Route 53 public DNS
      |
      v
ACM + ALB or API Gateway
      |
      v
Public subnets: ALB, NAT gateway when required
      |
      v
Private subnets: EKS managed nodes and pods
      |          |              |
      |          |              +--> S3 via VPC endpoint where possible
      |          +--> Secrets Manager / SSM / CloudWatch via VPC endpoints
      |
      v
Database subnets: RDS PostgreSQL and optional graph database

Each production region repeats this pattern independently:

prod ca-central-1   prod us-east-1   prod eu-west-1
VPC + EKS + RDS     VPC + EKS + RDS  VPC + EKS + RDS
```

## Networking

- VPCs are regional and environment-specific.
- Public subnets are for ALB and NAT gateways only.
- EKS nodes and application pods run in private subnets.
- RDS and graph databases run in database subnets without a default internet route.
- VPC endpoints are enabled for common AWS APIs to reduce NAT dependency.
- Dev uses a single NAT gateway to reduce cost; staging and prod use one NAT per AZ.

## EKS

The EKS module creates the control plane, managed node groups, OIDC provider for
IRSA, core add-ons, and control-plane logs. The Kubernetes API endpoint is
private-enabled in all environments. Public endpoint access is allowed only for
explicit CIDRs in the examples and should be disabled or tightly restricted for
production.

AWS permissions for pods should be granted through IRSA roles. The scaffold
supports workload-specific policies but intentionally does not attach broad pod
permissions by default.

## Data

RDS PostgreSQL is private, encrypted, backed up, and configured to let RDS manage
the master password in Secrets Manager. Terraform does not store the database
password.

For graph workloads, the default managed option is AWS Neptune. If the product
requires Neo4j-specific features, evaluate Neo4j Aura or a self-managed Neo4j
deployment in EKS with dedicated node groups, persistent volumes, backups, and a
clear operational owner.

## Terraform State

State lives in an encrypted, versioned S3 bucket created by
`infra/global/state-bootstrap`. Environment roots use native S3 lock files with
`use_lockfile = true`, avoiding new DynamoDB lock-table dependencies for fresh
Terraform 1.10+ setups.

## CI/CD

The workflow examples cover:

- `terraform fmt`
- `terraform validate`
- TFLint
- Checkov
- PR plans
- manual approval before apply through GitHub Environments
- dev -> staging -> prod promotion
- planning all production regions after adding a new region root
