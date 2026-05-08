#!/usr/bin/env bash
set -Eeuo pipefail

APP=""
NAMESPACE="default"
CONTAINER=""
IMAGE=""
REGIONS=""
CLUSTER_TEMPLATE="product-platform-prod-{region}-eks"
AWS_PROFILE=""
STEPS="5,10,25,50,100"
WATCH_SECONDS="300"
CHECK_INTERVAL="30"
LOG_SINCE="10m"
LOG_DIR=""
CANARY_SUFFIX="canary"
TRACK_LABEL="rollout-track"
STABLE_TRACK_VALUE="stable"
CANARY_TRACK_VALUE="canary"
SERVICE=""
ERROR_REGEX='(ERROR|Error|Exception|Traceback|panic|PANIC|fatal|FATAL|segmentation fault|OOMKilled|CrashLoopBackOff|ImagePullBackOff|ErrImagePull)'
EVENT_ERROR_REGEX='(Failed|FailedScheduling|BackOff|Unhealthy|Killing|OOMKilling|ImagePullBackOff|ErrImagePull|Insufficient cpu|Insufficient memory)'
MAX_RESTARTS="0"
AUTO_APPROVE_STEPS="0"
SKIP_KUBECONFIG="0"
REQUIRE_METRICS="0"
FAIL_IF_HPA_AT_MAX="1"
ROLLBACK_PROMOTED_ON_FAILURE="0"

CURRENT_REGION=""
CURRENT_CLUSTER=""
CURRENT_CONTEXT=""
CURRENT_OLD_IMAGE=""
CURRENT_ORIGINAL_REPLICAS=""
PROMOTED_REGIONS=()
declare -A PROMOTED_OLD_IMAGE=()
declare -A PROMOTED_REPLICAS=()
declare -A PROMOTED_CLUSTER=()

usage() {
  cat <<'EOF'
Usage:
  scripts/prod-progressive-deploy.sh \
    --app api \
    --namespace app \
    --container api \
    --image 123456789012.dkr.ecr.ca-central-1.amazonaws.com/api:2026-05-08.1 \
    --regions ca-central-1,us-east-1,eu-west-1

Required:
  --app                 Stable Kubernetes Deployment name.
  --container           Container name inside the Deployment to update.
  --image               New image to deploy.
  --regions             Comma-separated production regions.

Common options:
  --namespace           Kubernetes namespace. Default: default.
  --cluster-template    EKS cluster name template. Use {region}. Default: product-platform-prod-{region}-eks.
  --steps               Comma-separated canary percentages. Default: 5,10,25,50,100.
  --watch-seconds       Seconds to observe each increment. Default: 300.
  --check-interval      Seconds between health checks. Default: 30.
  --service             Optional Service name to verify selector safety.
  --auto-approve-steps  Do not prompt between increments.
  --skip-kubeconfig     Do not run aws eks update-kubeconfig.
  --aws-profile         AWS profile for aws eks update-kubeconfig.
  --rollback-promoted-on-failure
                        Roll back already promoted regions if a later region fails.

Prerequisite workload shape:
  The stable Deployment selector must include rollout-track=stable.
  The Service should select shared app labels, not rollout-track.

Why:
  The script creates a separate canary Deployment with rollout-track=canary.
  Traffic shifts by scaling stable and canary replica counts in each region.
EOF
}

log() {
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

die() {
  log "ERROR: $*"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required"
}

split_csv() {
  local value="$1"
  value="${value// /}"
  IFS=',' read -r -a CSV_RESULT <<< "$value"
}

cluster_for_region() {
  local region="$1"
  printf '%s\n' "${CLUSTER_TEMPLATE//\{region\}/$region}"
}

k() {
  kubectl --context "$CURRENT_CONTEXT" "$@"
}

ceil_percent() {
  local total="$1"
  local percent="$2"
  local value=$(( (total * percent + 99) / 100 ))

  if (( percent > 0 && value < 1 )); then
    value=1
  fi

  printf '%s\n' "$value"
}

confirm_or_stop() {
  local region="$1"
  local step="$2"

  if [[ "$AUTO_APPROVE_STEPS" == "1" ]]; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    die "Manual confirmation is required after ${step}% in ${region}, but stdin is not interactive. Use --auto-approve-steps for CI."
  fi

  local answer
  while true; do
    read -r -p "Continue after ${step}% in ${region}? [y] continue, [r] rollback this region, [q] rollback and stop: " answer
    case "$answer" in
      y|Y|yes|YES)
        return 0
        ;;
      r|R|rollback|ROLLBACK)
        rollback_current_region
        exit 1
        ;;
      q|Q|quit|QUIT)
        rollback_current_region
        log "Stopped by operator after rollback at ${step}% in ${region}."
        exit 1
        ;;
      *)
        printf 'Please answer y, r, or q.\n'
        ;;
    esac
  done
}

deployment_json() {
  local deployment="$1"
  k -n "$NAMESPACE" get deployment "$deployment" -o json
}

deployment_selector() {
  local deployment="$1"
  deployment_json "$deployment" | jq -r '.spec.selector.matchLabels | to_entries | map("\(.key)=\(.value)") | join(",")'
}

container_image() {
  local deployment="$1"
  deployment_json "$deployment" | jq -er --arg container "$CONTAINER" '.spec.template.spec.containers[] | select(.name == $container) | .image'
}

deployment_replicas() {
  local deployment="$1"
  deployment_json "$deployment" | jq -r '.spec.replicas // 1'
}

wait_for_rollout() {
  local deployment="$1"
  log "Waiting for rollout: ${deployment}"
  k -n "$NAMESPACE" rollout status "deployment/${deployment}" --timeout=10m
}

scale_deployment() {
  local deployment="$1"
  local replicas="$2"
  log "Scaling ${deployment} to ${replicas} replicas"
  k -n "$NAMESPACE" scale "deployment/${deployment}" --replicas="$replicas"
}

set_deployment_image() {
  local deployment="$1"
  local image="$2"
  log "Setting ${deployment}/${CONTAINER} image to ${image}"
  k -n "$NAMESPACE" set image "deployment/${deployment}" "${CONTAINER}=${image}" --record=false
}

delete_canary() {
  local canary="${APP}-${CANARY_SUFFIX}"
  log "Deleting canary deployment ${canary}"
  k -n "$NAMESPACE" delete deployment "$canary" --ignore-not-found=true --wait=true
}

rollback_current_region() {
  if [[ -z "$CURRENT_REGION" || -z "$CURRENT_CONTEXT" || -z "$CURRENT_OLD_IMAGE" || -z "$CURRENT_ORIGINAL_REPLICAS" ]]; then
    log "Rollback skipped because no active region state is available."
    return 0
  fi

  log "Rolling back ${CURRENT_REGION}: restoring ${APP} to ${CURRENT_OLD_IMAGE}"
  set_deployment_image "$APP" "$CURRENT_OLD_IMAGE" || true
  scale_deployment "$APP" "$CURRENT_ORIGINAL_REPLICAS" || true
  wait_for_rollout "$APP" || true
  delete_canary || true
}

rollback_promoted_regions() {
  if [[ "$ROLLBACK_PROMOTED_ON_FAILURE" != "1" ]]; then
    return 0
  fi

  if (( ${#PROMOTED_REGIONS[@]} == 0 )); then
    return 0
  fi

  log "Rolling back previously promoted regions because --rollback-promoted-on-failure is set."
  local index
  local region
  for (( index=${#PROMOTED_REGIONS[@]}-1; index>=0; index-- )); do
    region="${PROMOTED_REGIONS[$index]}"
    CURRENT_REGION="$region"
    CURRENT_CLUSTER="${PROMOTED_CLUSTER[$region]}"
    CURRENT_CONTEXT="${PROMOTED_CLUSTER[$region]}"
    CURRENT_OLD_IMAGE="${PROMOTED_OLD_IMAGE[$region]}"
    CURRENT_ORIGINAL_REPLICAS="${PROMOTED_REPLICAS[$region]}"

    if [[ "$SKIP_KUBECONFIG" != "1" ]]; then
      local args=(eks update-kubeconfig --region "$region" --name "$CURRENT_CLUSTER" --alias "$CURRENT_CLUSTER")
      if [[ -n "$AWS_PROFILE" ]]; then
        args+=(--profile "$AWS_PROFILE")
      fi
      aws "${args[@]}" || true
    fi

    rollback_current_region
  done
}

on_interrupt() {
  log "Interrupted. Rolling back active region if needed."
  rollback_current_region
  exit 130
}

on_error() {
  local exit_code="$?"
  log "Deployment failed with exit code ${exit_code}. Rolling back active region if needed."
  rollback_current_region
  rollback_promoted_regions
  exit "$exit_code"
}

preflight_region() {
  local region="$1"
  local cluster="$2"

  log "Preflight for region ${region}, cluster ${cluster}"

  if [[ "$SKIP_KUBECONFIG" != "1" ]]; then
    local args=(eks update-kubeconfig --region "$region" --name "$cluster" --alias "$cluster")
    if [[ -n "$AWS_PROFILE" ]]; then
      args+=(--profile "$AWS_PROFILE")
    fi
    aws "${args[@]}"
  fi

  CURRENT_CONTEXT="$cluster"

  k -n "$NAMESPACE" get deployment "$APP" >/dev/null

  container_image "$APP" >/dev/null || die "Container ${CONTAINER} not found in deployment ${APP}."

  local stable_track
  stable_track="$(deployment_json "$APP" | jq -r --arg label "$TRACK_LABEL" '.spec.selector.matchLabels[$label] // ""')"
  [[ "$stable_track" == "$STABLE_TRACK_VALUE" ]] || die "Deployment ${APP} selector must include ${TRACK_LABEL}=${STABLE_TRACK_VALUE}. Current value: ${stable_track:-<missing>}."

  if [[ -n "$SERVICE" ]]; then
    local service_track
    service_track="$(k -n "$NAMESPACE" get service "$SERVICE" -o json | jq -r --arg label "$TRACK_LABEL" '.spec.selector[$label] // ""')"
    [[ -z "$service_track" ]] || die "Service ${SERVICE} selector must not include ${TRACK_LABEL}; otherwise it cannot route to stable and canary together."
  fi

  CURRENT_OLD_IMAGE="$(container_image "$APP")"
  CURRENT_ORIGINAL_REPLICAS="$(deployment_replicas "$APP")"

  if (( CURRENT_ORIGINAL_REPLICAS < 2 )); then
    die "Deployment ${APP} has ${CURRENT_ORIGINAL_REPLICAS} replica. Progressive traffic shifting needs at least 2 replicas in production."
  fi

  log "Current image: ${CURRENT_OLD_IMAGE}"
  log "Original replicas: ${CURRENT_ORIGINAL_REPLICAS}"
}

create_canary() {
  local canary="${APP}-${CANARY_SUFFIX}"
  local replicas="$1"

  log "Creating canary deployment ${canary} with ${replicas} replicas"
  delete_canary

  deployment_json "$APP" | jq \
    --arg name "$canary" \
    --arg container "$CONTAINER" \
    --arg image "$IMAGE" \
    --arg track_label "$TRACK_LABEL" \
    --arg canary_track "$CANARY_TRACK_VALUE" \
    --arg run_id "$RUN_ID" \
    --argjson replicas "$replicas" '
      del(
        .status,
        .metadata.uid,
        .metadata.selfLink,
        .metadata.resourceVersion,
        .metadata.generation,
        .metadata.creationTimestamp,
        .metadata.managedFields,
        .metadata.ownerReferences,
        .metadata.annotations["deployment.kubernetes.io/revision"]
      )
      | .metadata.name = $name
      | .metadata.labels[$track_label] = $canary_track
      | .metadata.annotations["rollout.openai.com/run-id"] = $run_id
      | .spec.replicas = $replicas
      | .spec.selector.matchLabels[$track_label] = $canary_track
      | .spec.template.metadata.labels[$track_label] = $canary_track
      | .spec.template.metadata.annotations["rollout.openai.com/run-id"] = $run_id
      | .spec.template.spec.containers |= map(if .name == $container then .image = $image else . end)
    ' | k -n "$NAMESPACE" apply -f -

  wait_for_rollout "$canary"
}

canary_selector() {
  local canary="${APP}-${CANARY_SUFFIX}"
  deployment_selector "$canary"
}

capture_logs() {
  local region="$1"
  local step="$2"
  local selector="$3"
  local region_dir="${LOG_DIR}/${region}"

  mkdir -p "$region_dir"

  log "Capturing pod list, recent logs, warning events, and metrics for ${region} at ${step}%"
  k -n "$NAMESPACE" get pods -l "$selector" -o wide > "${region_dir}/pods-${step}.txt"
  k -n "$NAMESPACE" get pods -l "$selector" -o json > "${region_dir}/pods-${step}.json"
  k -n "$NAMESPACE" logs -l "$selector" --all-containers --since="$LOG_SINCE" --tail=-1 > "${region_dir}/logs-${step}.txt"
  k -n "$NAMESPACE" get events --field-selector type=Warning --sort-by=.lastTimestamp > "${region_dir}/events-${step}.txt" || true

  if k -n "$NAMESPACE" top pods -l "$selector" --containers > "${region_dir}/top-pods-${step}.txt" 2>&1; then
    log "Captured pod metrics for ${region} at ${step}%"
  else
    log "Pod metrics unavailable. Install metrics-server for CPU/memory checks."
    if [[ "$REQUIRE_METRICS" == "1" ]]; then
      return 1
    fi
  fi
}

health_check() {
  local region="$1"
  local step="$2"
  local selector
  selector="$(canary_selector)"

  capture_logs "$region" "$step" "$selector"

  local region_dir="${LOG_DIR}/${region}"

  local bad_pods
  bad_pods="$(jq -r --argjson max_restarts "$MAX_RESTARTS" '
    .items[]
    | .metadata.name as $pod
    | [
        (.status.containerStatuses // [])[]
        | select(
            ((.restartCount // 0) > $max_restarts)
            or ((.state.waiting.reason // "") | test("CrashLoopBackOff|ImagePullBackOff|ErrImagePull|CreateContainerConfigError|RunContainerError"))
            or ((.lastState.terminated.reason // "") == "OOMKilled")
          )
        | "\($pod): container=\(.name) restarts=\(.restartCount // 0) waiting=\(.state.waiting.reason // "-") lastTerminated=\(.lastState.terminated.reason // "-")"
      ]
      | .[]
  ' "${region_dir}/pods-${step}.json")"

  if [[ -n "$bad_pods" ]]; then
    log "Pod health failure:"
    printf '%s\n' "$bad_pods"
    return 1
  fi

  if grep -E "$ERROR_REGEX" "${region_dir}/logs-${step}.txt" >/dev/null 2>&1; then
    log "Application log error pattern matched. See ${region_dir}/logs-${step}.txt"
    grep -E "$ERROR_REGEX" "${region_dir}/logs-${step}.txt" | tail -50
    return 1
  fi

  if grep -E "$EVENT_ERROR_REGEX" "${region_dir}/events-${step}.txt" | grep -E "${APP}|${APP}-${CANARY_SUFFIX}" >/dev/null 2>&1; then
    log "Kubernetes warning event matched. See ${region_dir}/events-${step}.txt"
    grep -E "$EVENT_ERROR_REGEX" "${region_dir}/events-${step}.txt" | grep -E "${APP}|${APP}-${CANARY_SUFFIX}" | tail -50
    return 1
  fi

  if [[ "$FAIL_IF_HPA_AT_MAX" == "1" ]] && k -n "$NAMESPACE" get hpa "$APP" >/dev/null 2>&1; then
    local hpa_at_max
    hpa_at_max="$(k -n "$NAMESPACE" get hpa "$APP" -o json | jq -r 'if ((.status.currentReplicas // 0) >= (.spec.maxReplicas // 999999)) then "yes" else "no" end')"
    if [[ "$hpa_at_max" == "yes" ]]; then
      log "HPA ${APP} is at max replicas. This rollout likely needs more running power before continuing."
      return 1
    fi
  fi

  log "Health check passed for ${region} at ${step}%"
}

observe_step() {
  local region="$1"
  local step="$2"
  local elapsed=0

  while (( elapsed <= WATCH_SECONDS )); do
    health_check "$region" "$step"
    if (( elapsed == WATCH_SECONDS )); then
      break
    fi
    sleep "$CHECK_INTERVAL"
    elapsed=$((elapsed + CHECK_INTERVAL))
  done
}

set_traffic_step() {
  local region="$1"
  local percent="$2"
  local canary="${APP}-${CANARY_SUFFIX}"
  local canary_replicas
  local stable_replicas

  canary_replicas="$(ceil_percent "$CURRENT_ORIGINAL_REPLICAS" "$percent")"
  if (( canary_replicas > CURRENT_ORIGINAL_REPLICAS )); then
    canary_replicas="$CURRENT_ORIGINAL_REPLICAS"
  fi
  stable_replicas=$((CURRENT_ORIGINAL_REPLICAS - canary_replicas))

  log "Region ${region}: requested ${percent}% canary, setting stable=${stable_replicas}, canary=${canary_replicas}"
  scale_deployment "$APP" "$stable_replicas"
  scale_deployment "$canary" "$canary_replicas"
  wait_for_rollout "$APP"
  wait_for_rollout "$canary"
  observe_step "$region" "$percent"
  confirm_or_stop "$region" "$percent"
}

promote_region() {
  local region="$1"
  log "Promoting ${IMAGE} to stable deployment in ${region}"
  set_deployment_image "$APP" "$IMAGE"
  scale_deployment "$APP" "$CURRENT_ORIGINAL_REPLICAS"
  wait_for_rollout "$APP"
  delete_canary
  PROMOTED_OLD_IMAGE["$region"]="$CURRENT_OLD_IMAGE"
  PROMOTED_REPLICAS["$region"]="$CURRENT_ORIGINAL_REPLICAS"
  PROMOTED_CLUSTER["$region"]="$CURRENT_CLUSTER"
  PROMOTED_REGIONS+=("$region")
  log "Region ${region} promoted successfully."
}

deploy_region() {
  local region="$1"
  local cluster
  cluster="$(cluster_for_region "$region")"

  CURRENT_REGION="$region"
  CURRENT_CLUSTER="$cluster"
  CURRENT_CONTEXT="$cluster"

  preflight_region "$region" "$cluster"

  split_csv "$STEPS"
  local steps=("${CSV_RESULT[@]}")
  local canary_created="0"
  local step

  for step in "${steps[@]}"; do
    [[ "$step" =~ ^[0-9]+$ ]] || die "Invalid step '${step}'. Use integer percentages."
    (( step > 0 && step <= 100 )) || die "Step '${step}' must be between 1 and 100."

    if (( step == 100 )); then
      promote_region "$region"
      canary_created="0"
      return 0
    fi

    if [[ "$canary_created" == "0" ]]; then
      create_canary "$(ceil_percent "$CURRENT_ORIGINAL_REPLICAS" "$step")"
      canary_created="1"
    fi

    set_traffic_step "$region" "$step"
  done

  promote_region "$region"
}

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --app) APP="$2"; shift 2 ;;
      --namespace) NAMESPACE="$2"; shift 2 ;;
      --container) CONTAINER="$2"; shift 2 ;;
      --image) IMAGE="$2"; shift 2 ;;
      --regions) REGIONS="$2"; shift 2 ;;
      --cluster-template) CLUSTER_TEMPLATE="$2"; shift 2 ;;
      --aws-profile) AWS_PROFILE="$2"; shift 2 ;;
      --steps) STEPS="$2"; shift 2 ;;
      --watch-seconds) WATCH_SECONDS="$2"; shift 2 ;;
      --check-interval) CHECK_INTERVAL="$2"; shift 2 ;;
      --log-since) LOG_SINCE="$2"; shift 2 ;;
      --log-dir) LOG_DIR="$2"; shift 2 ;;
      --service) SERVICE="$2"; shift 2 ;;
      --error-regex) ERROR_REGEX="$2"; shift 2 ;;
      --max-restarts) MAX_RESTARTS="$2"; shift 2 ;;
      --auto-approve-steps) AUTO_APPROVE_STEPS="1"; shift ;;
      --skip-kubeconfig) SKIP_KUBECONFIG="1"; shift ;;
      --require-metrics) REQUIRE_METRICS="1"; shift ;;
      --allow-hpa-at-max) FAIL_IF_HPA_AT_MAX="0"; shift ;;
      --rollback-promoted-on-failure) ROLLBACK_PROMOTED_ON_FAILURE="1"; shift ;;
      -h|--help) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done

  [[ -n "$APP" ]] || die "--app is required"
  [[ -n "$CONTAINER" ]] || die "--container is required"
  [[ -n "$IMAGE" ]] || die "--image is required"
  [[ -n "$REGIONS" ]] || die "--regions is required"
  [[ "$WATCH_SECONDS" =~ ^[0-9]+$ ]] || die "--watch-seconds must be an integer"
  [[ "$CHECK_INTERVAL" =~ ^[0-9]+$ ]] || die "--check-interval must be an integer"
  [[ "$MAX_RESTARTS" =~ ^[0-9]+$ ]] || die "--max-restarts must be an integer"
}

main() {
  parse_args "$@"

  require_cmd aws
  require_cmd kubectl
  require_cmd jq

  RUN_ID="${RUN_ID:-$(date -u '+%Y%m%dT%H%M%SZ')}"
  if [[ -z "$LOG_DIR" ]]; then
    LOG_DIR="rollout-logs/${RUN_ID}-${APP}"
  fi
  mkdir -p "$LOG_DIR"

  exec > >(tee -a "${LOG_DIR}/rollout.log") 2>&1

  trap on_interrupt INT TERM
  trap on_error ERR

  log "Starting production progressive deployment"
  log "App=${APP} Namespace=${NAMESPACE} Container=${CONTAINER}"
  log "Image=${IMAGE}"
  log "Regions=${REGIONS}"
  log "Steps=${STEPS}"
  log "Logs=${LOG_DIR}"

  split_csv "$REGIONS"
  local regions=("${CSV_RESULT[@]}")
  local region

  for region in "${regions[@]}"; do
    log "===== Deploying region ${region} ====="
    deploy_region "$region"
    CURRENT_REGION=""
    CURRENT_CLUSTER=""
    CURRENT_CONTEXT=""
    CURRENT_OLD_IMAGE=""
    CURRENT_ORIGINAL_REPLICAS=""
  done

  log "All requested production regions promoted successfully."
}

main "$@"
