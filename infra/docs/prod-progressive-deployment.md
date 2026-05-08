# Production Progressive Deployment

Use `scripts/prod-progressive-deploy.sh` to roll an application image through
production region by region. The script creates a canary Deployment, shifts a
percentage of traffic by replica count, checks logs/events/pod health, and then
either continues, promotes, or rolls back.

## Workload Prerequisites

The script expects a Kubernetes canary-safe shape:

- Stable Deployment name: `api`
- Stable Deployment selector includes `rollout-track=stable`
- Canary Deployment will be created as `api-canary`
- Service selector must use shared app labels and must not include
  `rollout-track`

Example selector model:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: api
      rollout-track: stable
  template:
    metadata:
      labels:
        app.kubernetes.io/name: api
        rollout-track: stable
---
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app.kubernetes.io/name: api
```

This keeps the stable and canary Deployments from fighting over the same pods,
while the Service can route to both sets of endpoints.

## Example

```bash
scripts/prod-progressive-deploy.sh \
  --app api \
  --namespace app \
  --container api \
  --image 123456789012.dkr.ecr.ca-central-1.amazonaws.com/api:2026-05-08.1 \
  --regions ca-central-1,us-east-1,eu-west-1 \
  --cluster-template 'product-platform-prod-{region}-eks' \
  --service api \
  --steps 5,10,25,50,100
```

By default, the script pauses after each increment and asks the operator whether
to continue, roll back, or stop. In GitHub Actions, the workflow runs on merge to
`main` and uses `--auto-approve-steps`; approval is handled by the
`production-progressive` GitHub Environment before the deploy job starts.

## Merge-To-Main Approval

Configure the repository environment named `production-progressive` with required
reviewers. Add the repository owner or an owners team as the required reviewer.
GitHub will start the workflow on push to `main`, then pause the deploy job until
that approval is granted.

For push-to-main runs, set these repository variables:

- `AWS_PROD_DEPLOY_ROLE_ARN`
- `PROD_DEPLOY_APP`, for example `api`
- `PROD_DEPLOY_NAMESPACE`, for example `app`
- `PROD_DEPLOY_CONTAINER`, for example `api`
- `PROD_DEPLOY_IMAGE`, for example the immutable ECR image tag to roll out
- `PROD_DEPLOY_REGIONS`, for example `ca-central-1,us-east-1,eu-west-1`
- `PROD_DEPLOY_STEPS`, optional, defaults to `5,10,25,50,100`

The workflow still supports manual dispatch when you need to override those
values for an operator-led rollout.

## What Gets Checked

- Canary rollout status
- Stable rollout status after scaling
- Pod waiting states such as `CrashLoopBackOff`, `ImagePullBackOff`, and
  `CreateContainerConfigError`
- Container restarts above `--max-restarts`
- Recent canary logs matching the error regex
- Warning events such as failed scheduling, unhealthy probes, OOM kills, or
  insufficient CPU/memory
- HPA at max replicas, unless `--allow-hpa-at-max` is set
- Pod metrics when metrics-server is available

Logs and snapshots are written to `rollout-logs/<run-id>-<app>/`.

## Rollback Behavior

If a canary step fails, the script:

- restores the stable Deployment image to the previous image
- scales the stable Deployment back to its original replica count
- deletes the canary Deployment
- stops before the next region

If the operator presses `Ctrl-C`, the active region is rolled back. Previously
promoted regions are left alone by default because automatic cross-region
rollback can be risky for data and dependency compatibility. If
`--rollback-promoted-on-failure` is set, the script rolls previously promoted
regions back in reverse order by restoring the old stable image and replica
count. Use that flag only when the team has explicitly approved cross-region
rollback behavior.

## Capacity Notes

Replica-based traffic shifting is approximate. A 5% canary on a 3-replica
service becomes one canary pod and two stable pods, which is roughly 33% canary.
For meaningful small increments, production services need enough replicas. The
script refuses to canary a single-replica Deployment.

If HPA is already maxed, pods are pending, or events show insufficient CPU or
memory, the script stops and rolls back the active region. That is a capacity
signal, not just an application error.
