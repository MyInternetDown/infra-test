# Risks And Decisions

## Decisions To Make Before Production

- AWS account strategy: one account per environment, one account per region, or shared account with strict boundaries.
- Whether production Kubernetes API endpoints should be private-only.
- Whether public services use ALB directly, API Gateway in front of ALB, or both.
- Whether graph workloads require Neo4j compatibility or can use AWS Neptune.
- Exact RPO/RTO targets for PostgreSQL, graph data, and object storage.
- Multi-region traffic strategy: active-active, active-passive, or regional client pinning.
- Client isolation model inside a production region: namespace, database schema, database instance, or account-level isolation.
- Container image promotion strategy and vulnerability gate.
- Secret value injection and rotation workflow.
- Centralized logging and SIEM integration.

## Known Risks In This Starter

- GitHub deploy role permissions are intentionally not filled in. A team lead must review the final policy.
- Kubernetes workloads, Helm releases, NetworkPolicies, and admission controls are not included in this first Terraform layer.
- ALB creation is expected to happen through AWS Load Balancer Controller or a later ingress layer.
- The Neo4j module defaults to AWS Neptune as a managed graph equivalent, not Neo4j itself.
- Example EKS versions and instance sizes must be checked against the target account, region, and date before apply.
- Production budgets are placeholders and must be based on real forecasts.
