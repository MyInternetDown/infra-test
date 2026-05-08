# Cost Control Checklist

- Review NAT gateway cost. Production uses one NAT per AZ for availability; dev uses one NAT to reduce spend.
- Prefer VPC endpoints for AWS APIs used by private workloads.
- Right-size EKS node groups after load testing.
- Use Spot only for fault-tolerant workloads and separate those workloads with labels/taints.
- Set CloudWatch log retention intentionally; production examples use 90 days.
- Review RDS instance class, storage autoscaling limits, Performance Insights retention, and backup retention.
- Enable budgets and alerts before production traffic.
- Tag all resources with owner, environment, region, and cost center.
- Review inter-region data transfer before enabling active-active production traffic.
- Treat Neptune or self-managed Neo4j as a significant cost decision, not a default checkbox.
- Avoid creating unused public hosted zones, NAT gateways, and load balancers in every sandbox.
