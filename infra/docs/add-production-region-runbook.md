# Add A Production Region

This runbook adds a new isolated production region without copying module logic.

## 1. Gather Inputs

- AWS region, for example `ap-southeast-2`
- Three usable AZ names where possible
- Non-overlapping VPC CIDR
- Public, private, and database subnet CIDRs
- Regional DNS name, for example `ap-southeast-2.prod.example.com`
- Expected client count and traffic profile
- RDS size, EKS node size, and graph database decision
- Compliance or data residency constraints

## 2. Create The Thin Root

```bash
cp -R infra/envs/prod/_template infra/envs/prod/<new-region>
```

Then edit:

- `backend.tf`: replace `PLACEHOLDER-REGION` in the state key.
- `terraform.tfvars`: replace region, AZs, CIDRs, DNS names, sizing, and tags.

Do not edit `infra/stacks/regional-platform` unless the architecture for every
region needs to change.

## 3. Open A Pull Request

The new-region workflow plans all `infra/envs/prod/*` roots except `_template`.
Review the plan for:

- VPC CIDR overlap
- public database exposure
- unexpected IAM wildcards
- NAT gateway count
- RDS deletion protection
- log retention
- KMS encryption

## 4. Apply With Approval

Use the promotion workflow or a region-specific apply workflow after approval.
The GitHub Environment for `production-<new-region>` should require reviewers.

## 5. Post-Apply Checks

- Confirm EKS cluster endpoint and node readiness.
- Confirm RDS is private and reachable only from EKS workloads.
- Confirm ALB certificate validation.
- Confirm CloudWatch alarms and SNS subscriptions.
- Confirm budgets and tags.
- Confirm DNS records and client routing.
- Run application smoke tests.

## 6. Rollback

Infrastructure rollback is usually a forward fix. Do not destroy a production
region unless the team has confirmed there is no customer data, no active DNS,
and final database snapshots have been taken.
