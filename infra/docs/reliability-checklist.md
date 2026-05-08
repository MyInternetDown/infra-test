# Reliability Checklist

- Use at least two AZs for dev/staging and three AZs for production where the region supports it.
- Use one NAT gateway per AZ for production unless the team accepts cross-AZ egress failure risk.
- Enable RDS Multi-AZ for staging and production.
- Set RDS backup retention based on the product RPO and compliance needs.
- Test database restore procedures before production launch.
- Define DNS failover or traffic steering strategy for multi-region production.
- Keep production regions isolated so one regional failure does not mutate another region.
- Set EKS node group min/desired/max sizes from real load tests.
- Add pod disruption budgets, horizontal pod autoscaling, and cluster autoscaler or Karpenter in the Kubernetes layer.
- Monitor EKS control plane logs, RDS metrics, ALB 5xx rates, target health, NAT errors, and application SLOs.
- Document EKS and RDS upgrade windows.
- Keep runbooks for regional failover, database restore, secret rotation, and rollback.
- Run game days for region loss and dependency loss.
