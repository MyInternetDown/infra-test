#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose_file="${repo_root}/docker-compose.localstack.yml"
tf_root="${repo_root}/infra/tests/localstack"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required for the LocalStack smoke test." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose is required for the LocalStack smoke test." >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required for the LocalStack smoke test." >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required for the LocalStack smoke test health check." >&2
  exit 1
fi

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

docker compose -f "${compose_file}" up -d

for attempt in {1..60}; do
  if curl -fsS "http://127.0.0.1:4566/_localstack/health" >/dev/null 2>&1; then
    break
  fi

  if [[ "${attempt}" == "60" ]]; then
    echo "LocalStack did not become healthy in time." >&2
    docker compose -f "${compose_file}" logs localstack >&2
    exit 1
  fi

  sleep 2
done

terraform -chdir="${tf_root}" init -input=false
terraform -chdir="${tf_root}" validate
terraform -chdir="${tf_root}" plan -input=false -out=tfplan

if [[ "${APPLY:-0}" == "1" ]]; then
  terraform -chdir="${tf_root}" apply -input=false -auto-approve tfplan
fi
