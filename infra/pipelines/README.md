# Pipeline Examples

GitHub Actions examples live in `.github/workflows` so they can run directly
when the repository is connected to GitHub.

Workflows included:

- `terraform-pr.yml`: fmt, validate, TFLint, Checkov, and PR plans.
- `terraform-promote.yml`: manual dev -> staging -> prod promotion with GitHub Environment approval.
- `terraform-new-prod-region.yml`: discovers production region roots and plans them on PRs.

Required GitHub repository variables:

- `AWS_TERRAFORM_PLAN_ROLE_ARN`
- `AWS_TERRAFORM_APPLY_ROLE_ARN`
- `TF_STATE_BUCKET`
- `TF_STATE_REGION`, for example `ca-central-1`

Configure GitHub Environments named `dev`, `staging`, and
`production-<region>` with required reviewers before enabling production apply.
