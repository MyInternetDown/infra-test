.PHONY: localstack-up localstack-down localstack-logs localstack-smoke localstack-plan localstack-apply localstack-destroy

LOCALSTACK_COMPOSE := docker-compose.localstack.yml
LOCALSTACK_ROOT := infra/tests/localstack

localstack-up:
	docker compose -f $(LOCALSTACK_COMPOSE) up -d

localstack-down:
	docker compose -f $(LOCALSTACK_COMPOSE) down

localstack-logs:
	docker compose -f $(LOCALSTACK_COMPOSE) logs -f localstack

localstack-smoke:
	./scripts/localstack-smoke.sh

localstack-plan:
	terraform -chdir=$(LOCALSTACK_ROOT) init -input=false
	terraform -chdir=$(LOCALSTACK_ROOT) validate
	terraform -chdir=$(LOCALSTACK_ROOT) plan -input=false

localstack-apply:
	terraform -chdir=$(LOCALSTACK_ROOT) init -input=false
	terraform -chdir=$(LOCALSTACK_ROOT) apply -input=false

localstack-destroy:
	terraform -chdir=$(LOCALSTACK_ROOT) destroy -input=false
