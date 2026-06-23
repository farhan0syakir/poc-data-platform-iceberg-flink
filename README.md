# Local Open-Source Data Platform (Iceberg + Flink)

This repository provides a local Docker Compose stack that mirrors the AWS architecture from your diagram, but with open-source components.

## Architecture Diagrams

![AWS architecture reference](images/aws-architecture.png)

## Architecture Mapping (AWS -> Open Source)

- Amazon S3 -> MinIO
- AWS Glue Data Catalog -> Project Nessie catalog
- Amazon Managed Service for Apache Flink -> Apache Flink (JobManager + TaskManager)
- Amazon CloudWatch -> Prometheus + Grafana
- Browser SQL console -> SQLPad
- Checkpoint bucket on S3 -> `checkpoints` bucket in MinIO
- Downstream consumers -> Trino (query engine over Iceberg tables)

## Included Services

- `minio` (S3-compatible object storage)
- `minio-init` (creates `raw`, `warehouse`, and `checkpoints` buckets)
- `postgres` (metadata DB for Nessie)
- `nessie` (Iceberg catalog/versioned metadata)
- `flink-jobmanager` and `flink-taskmanager` (stream processing)
- `trino` (SQL query engine for Iceberg)
- `sqlpad` (browser-based SQL editor for Trino)
- `prometheus` and `grafana` (metrics and dashboards)

## Quick Start

### 1) Start everything

```bash
docker compose up -d
```

### 2) Run a smoke test (creates and queries an Iceberg table)

```bash
chmod +x scripts/smoke-test.sh
./scripts/smoke-test.sh
```

### 3) Stop everything

```bash
docker compose down
```

To also delete local volumes:

```bash
docker compose down -v
```

## Endpoints

- MinIO API: `http://localhost:9000`
- MinIO Console: `http://localhost:9001` (user/password: `minioadmin` / `minioadmin`)
- Nessie API: `http://localhost:19120`
- Flink UI: `http://localhost:8081`
- Trino: `http://localhost:8080`
- SQLPad: `http://localhost:3010`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000` (user/password: `admin` / `admin`)

## Screenshots

### SQLPad Query Result

![SQLPad query result](images/sqlpad.png)

### MinIO Console

![MinIO console](images/minio.png)

## Notes

- Flink is configured to store checkpoints in MinIO (`s3://checkpoints/flink`).
- Trino is configured with the Iceberg connector backed by Nessie + MinIO.
- SQLPad provides a browser-based SQL editor connected to Trino.
- This stack is designed for local development and POC use.

## SQLPad Browser SQL Editor Setup

SQLPad is available at `http://localhost:3010` and provides a web-based SQL editor for Trino queries.

Connection management is intentionally hidden in this setup because `SQLPAD_AUTH_DISABLED=true` runs SQLPad in no-auth mode (non-admin UI). The Trino connection is preconfigured via `docker-compose.yml`.

### Step 1: Open SQLPad

Visit: `http://localhost:3010`

### Step 2: Run Your First Query

1. Click the **new query** button (or home icon)
2. Select **Trino** from the connection dropdown (it is already available)
3. Run a test query:

```sql
SHOW CATALOGS;
```

Or query your data:

```sql
SELECT * FROM iceberg.demo.events LIMIT 10;
```

## Reference

- https://aws.amazon.com/blogs/big-data/building-unified-data-pipelines-with-apache-iceberg-and-apache-flink/

