COMPOSE := docker compose
VOLUMES := database_mysql_data database_postgres_data \
           database_mongo_data database_mongo_config \
           database_redis_data queue_rabbitmq_data \
           storage_minio_data \
           monitoring_grafana_data monitoring_loki_data
NETWORK := app-network
ALL_PROFILES := --profile database --profile cache --profile queue --profile storage --profile monitoring --profile gateway

.PHONY: install up down restart ps logs \
        up-database up-cache up-queue up-storage up-monitoring up-gateway \
        down-database down-cache down-queue down-storage down-monitoring down-gateway

install:
	@for v in $(VOLUMES); do docker volume create $$v >/dev/null && echo "✓ volume $$v"; done
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK) >/dev/null
	@echo "✓ network $(NETWORK)"

up:
	$(COMPOSE) $(ALL_PROFILES) up -d

down:
	$(COMPOSE) $(ALL_PROFILES) down

restart: down up

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f $(SVC)

up-database:
	$(COMPOSE) --profile database up -d

up-cache:
	$(COMPOSE) --profile cache up -d

up-queue:
	$(COMPOSE) --profile queue up -d

up-storage:
	$(COMPOSE) --profile storage up -d

up-monitoring:
	$(COMPOSE) --profile monitoring up -d

up-gateway:
	$(COMPOSE) --profile gateway up -d

down-database:
	$(COMPOSE) --profile database down

down-cache:
	$(COMPOSE) --profile cache down

down-queue:
	$(COMPOSE) --profile queue down

down-storage:
	$(COMPOSE) --profile storage down

down-monitoring:
	$(COMPOSE) --profile monitoring down

down-gateway:
	$(COMPOSE) --profile gateway down
