# infra-stack

本地开发的基础设施栈，一键启停 mysql / postgres / mongo / redis / rabbitmq / grafana / loki / alloy / nginx。

也提供 `compose.prod.yaml` 作为单机 self-host 生产部署基线。生产模式默认只将 Nginx 暴露到公网，数据库、缓存、队列、对象存储和监控端口绑定到 `127.0.0.1`，业务容器通过 `app-network` 内网访问。

## 首次使用

```bash
make install   # 幂等创建 volume + network（已有数据的 volume 会保留）
make up        # 启动全部
```

## 日常命令

| 命令 | 说明 |
|---|---|
| `make up` / `make down` | 全栈启停 |
| `make restart` | 全栈重启 |
| `make ps` | 查看状态 |
| `make logs SVC=mysql` | 跟某服务日志 |
| `make up-database` / `make down-database` | 仅 mysql + postgres + mongo |
| `make up-cache` / `make down-cache` | 仅 redis |
| `make up-queue` / `make down-queue` | 仅 rabbitmq |
| `make up-monitoring` / `make down-monitoring` | 仅 grafana + loki + alloy |
| `make up-gateway` / `make down-gateway` | 仅 nginx |

## 生产部署

首次部署：

```bash
make init-prod-env
make prod-install
make prod-up
```

日常命令：

| 命令 | 说明 |
|---|---|
| `make prod-up` / `make prod-down` | 生产栈启停 |
| `make prod-restart` | 生产栈重启 |
| `make prod-ps` | 查看生产服务状态 |
| `make prod-logs SVC=postgres` | 跟生产服务日志 |

生产配置要点：

- `.env` 不要提交到 Git，仓库只保留 `config/.env.example`。
- `make init-prod-env` 会生成随机生产密码；如果 `.env` 已存在，会拒绝覆盖。
- Nginx 监听 `80/443`，证书建议放在 `gateway/nginx/certs/`，server block 放在 `gateway/nginx/conf.d/`。
- MySQL、Postgres、Mongo、Redis、RabbitMQ、MinIO、Grafana、Loki 默认只绑定本机端口；如需公网访问，应优先通过 VPN、堡垒机或 Nginx TLS 反代。
- `compose.prod.yaml` 复用 external volumes。生产环境必须单独设计备份：数据库 dump/WAL、MinIO bucket 同步、Grafana/Loki 数据备份。
- 首次上线前执行 `docker compose -f compose.prod.yaml --profile database --profile cache --profile queue --profile storage --profile monitoring --profile gateway config` 检查配置。

## 服务端点

| 服务 | 端口 | 用户 | 密码 |
|---|---|---|---|
| mysql | 3306 | root | root |
| postgres | 5432 | postgres | postgres |
| mongo | 27017 | root | root |
| redis | 6379 | - | - |
| rabbitmq (AMQP) | 5672 | admin | admin |
| rabbitmq (UI) | 15672 | admin | admin |
| grafana | 3000 | admin | admin |
| loki | 3100 | - | - |
| nginx | 8010 / 8020 / 8030 / 8040 | - | - |

## 网络

所有容器挂在 `app-network` 上。业务容器只需 `docker run --network app-network ...`（或 compose 里 `networks: [app-network]` + `external: true`），就能用 hostname 互通（如 `mysql:3306`、`redis:6379`）。

## 数据 volume

全部 `external: true`，由 `make install` 创建：

- `database_mysql_data`, `database_postgres_data`, `database_mongo_data`, `database_mongo_config`
- `database_redis_data`
- `queue_rabbitmq_data`
- `storage_minio_data`
- `monitoring_grafana_data`, `monitoring_loki_data`

`make down` 不会删 volume。要删数据请手动 `docker volume rm <name>`。

## 目录

```
infra-stack/
├── compose.yaml
├── compose.prod.yaml
├── Makefile
├── config/
│   └── .env.example
├── database/
│   ├── mysql/           (预留自定义)
│   ├── postgres/        postgresql.conf, pg_hba.conf, postgresql.prod.conf, pg_hba.prod.conf
│   └── mongo/           (预留自定义)
├── cache/redis/         (预留自定义)
├── queue/rabbitmq/      (预留自定义)
├── monitoring/
│   ├── loki/config.yml
│   ├── alloy/config.alloy
│   └── grafana/provisioning/  (预留预置 datasource / dashboard)
└── gateway/
    └── nginx/
        ├── nginx.conf
        ├── conf.d/      ← 你自己的 server block 放这里
        └── certs/       ← prod TLS 证书放这里
```

## 日志采集

Alloy 通过 `/var/run/docker.sock` 自动发现本机**所有** docker 容器，推送日志到 Loki（tenant_id=`fake`，retention 168h）。

在 Grafana 里加 Loki datasource（URL = `http://loki:3100`），即可用 LogQL 查询：

```
{container="mysql"}
{service="redis"} |= "error"
```
