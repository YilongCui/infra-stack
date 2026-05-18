COMPOSE := docker compose
PROD_COMPOSE := docker compose -f compose.prod.yaml
VOLUMES := database_mysql_data database_postgres_data \
           database_mongo_data database_mongo_config \
           database_redis_data queue_rabbitmq_data \
           storage_minio_data \
           monitoring_grafana_data monitoring_loki_data
NETWORK := app-network
ALL_PROFILES := --profile database --profile cache --profile queue --profile storage --profile monitoring --profile gateway

.PHONY: install up down restart ps logs \
        up-database up-cache up-queue up-storage up-monitoring up-gateway \
        down-database down-cache down-queue down-storage down-monitoring down-gateway \
        init-prod-env prod-install prod-up prod-down prod-restart prod-ps prod-logs

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

init-prod-env:
	@test ! -f .env || (echo ".env already exists. Refusing to overwrite production secrets."; exit 1)
	@{ \
		echo "MYSQL_ROOT_PASSWORD=$$(openssl rand -hex 32)"; \
		echo ""; \
		echo "POSTGRES_USER=postgres"; \
		echo "POSTGRES_PASSWORD=$$(openssl rand -hex 32)"; \
		echo ""; \
		echo "MONGO_INITDB_ROOT_USERNAME=root"; \
		echo "MONGO_INITDB_ROOT_PASSWORD=$$(openssl rand -hex 32)"; \
		echo ""; \
		echo "REDIS_PASSWORD=$$(openssl rand -hex 32)"; \
		echo ""; \
		echo "RABBITMQ_DEFAULT_USER=admin"; \
		echo "RABBITMQ_DEFAULT_PASS=$$(openssl rand -hex 32)"; \
		echo ""; \
		echo "MINIO_ROOT_USER=minioadmin"; \
		echo "MINIO_ROOT_PASSWORD=$$(openssl rand -hex 32)"; \
		echo ""; \
		echo "GF_SECURITY_ADMIN_USER=admin"; \
		echo "GF_SECURITY_ADMIN_PASSWORD=$$(openssl rand -hex 32)"; \
		echo ""; \
		echo "MYSQL_BIND_PORT=3306"; \
		echo "POSTGRES_BIND_PORT=5432"; \
		echo "MONGO_BIND_PORT=27017"; \
		echo "REDIS_BIND_PORT=6379"; \
		echo "RABBITMQ_AMQP_BIND_PORT=5672"; \
		echo "RABBITMQ_UI_BIND_PORT=15672"; \
		echo "MINIO_API_BIND_PORT=9000"; \
		echo "MINIO_CONSOLE_BIND_PORT=9001"; \
		echo "GRAFANA_BIND_PORT=3000"; \
		echo "LOKI_BIND_PORT=3100"; \
		echo "NGINX_HTTP_BIND_PORT=80"; \
		echo "NGINX_HTTPS_BIND_PORT=443"; \
	} > .env
	@chmod 600 .env
	@echo "Generated .env with random production passwords."

prod-install: install
	@test -f .env || (echo "Missing .env. Run make init-prod-env first."; exit 1)

prod-up: prod-install
	$(PROD_COMPOSE) $(ALL_PROFILES) up -d

prod-down:
	$(PROD_COMPOSE) $(ALL_PROFILES) down

prod-restart: prod-down prod-up

prod-ps:
	$(PROD_COMPOSE) ps

prod-logs:
	$(PROD_COMPOSE) logs -f $(SVC)
