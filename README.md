# Local Open-Source Data Platform (Iceberg + Flink)

This repository provides a local Docker Compose stack that mirrors the AWS architecture from your diagram, but with open-source components.

## Architecture Diagrams

![AWS architecture reference](images/aws-architecture.png)

## Architecture Mapping (AWS -> Open Source)

- Amazon S3 -> MinIO
- AWS Glue Data Catalog -> Project Nessie catalog
- Amazon Managed Service for Apache Flink -> Apache Flink (JobManager + TaskManager)
- Amazon CloudWatch -> Prometheus + Grafana
- Checkpoint bucket on S3 -> `checkpoints` bucket in MinIO
- Downstream consumers -> Trino (query engine over Iceberg tables)

## Included Services

- `minio` (S3-compatible object storage)
- `minio-init` (creates `raw`, `warehouse`, and `checkpoints` buckets)
- `postgres` (metadata DB for Nessie)
- `nessie` (Iceberg catalog/versioned metadata)
- `flink-jobmanager` and `flink-taskmanager` (stream processing)
- `trino` (SQL query engine for Iceberg)
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
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000` (user/password: `admin` / `admin`)

## Notes

- Flink is configured to store checkpoints in MinIO (`s3://checkpoints/flink`).
- Trino is configured with the Iceberg connector backed by Nessie + MinIO.
- This stack is designed for local development and POC use.

## Reference

- https://aws.amazon.com/blogs/big-data/building-unified-data-pipelines-with-apache-iceberg-and-apache-flink/

