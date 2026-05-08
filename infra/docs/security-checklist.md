# Security Checklist

- Replace all placeholder domains, emails, CIDRs, repository names, and state bucket names.
- Use GitHub OIDC or another short-lived identity provider; do not store AWS access keys in GitHub secrets.
- Attach a reviewed least-privilege policy to the GitHub deploy role before CI apply.
- Keep Terraform state encrypted, versioned, access-controlled, and locked.
- Restrict state bucket access to CI roles and break-glass platform roles only.
- Disable public database access. The RDS module sets `publicly_accessible = false`.
- Keep database subnets private with no default internet route.
- Restrict EKS public API CIDRs, or disable public endpoint access for production.
- Grant pod AWS access only with IRSA and workload-specific policies.
- Avoid wildcard IAM actions in workload policies.
- Store secret values outside Terraform state. Terraform should create secret metadata only.
- Enable KMS key rotation for application, database, secrets, and state encryption keys.
- Enable and review EKS audit logs.
- Use AWS WAF or API Gateway protections where public services need rate limiting or request filtering.
- Ensure ALB security groups expose only required ports.
- Require MFA and break-glass procedures for human production access.
