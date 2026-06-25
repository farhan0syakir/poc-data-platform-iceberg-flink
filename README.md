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

## Testing Examples

The examples below cover every layer of the stack — from raw object storage through Iceberg metadata, all the way to Flink streaming. Run them in order after `./scripts/smoke-test.sh` to verify the full platform.

---

### 1. Verify all services are running

```bash
docker compose ps
```

Expected: all containers `Up`, `minio-init` is `Exited 0`.

---

### 2. Browse MinIO buckets and Iceberg data files

Open the MinIO Console at `http://localhost:9001` (user/password: `minioadmin` / `minioadmin`) to browse the `raw`, `warehouse`, and `checkpoints` buckets. Navigate into `warehouse` to see Iceberg metadata (`.json`, `.avro`) and data files (`.parquet`) under `warehouse/demo/events/`.

![MinIO console](images/minio.png)

---

### 3. Query Iceberg via Trino (SQLPad)

Open SQLPad at `http://localhost:3010`, select **Trino** from the connection dropdown, and run your queries directly in the browser.

![SQLPad query result](images/sqlpad.png)

---

### 4. Iceberg time travel — query a previous snapshot

```bash
# List available snapshots
docker compose exec -T trino trino --execute \
  "SELECT snapshot_id, committed_at, operation FROM iceberg.demo.\"events\$snapshots\" ORDER BY committed_at"

# Replace <snapshot_id> with one from the output above
docker compose exec -T trino trino --execute \
  "SELECT * FROM iceberg.demo.events FOR VERSION AS OF <snapshot_id>"
```

---

### 5. Insert new data and verify row count changes

```bash
docker compose exec -T trino trino --execute \
  "INSERT INTO iceberg.demo.events VALUES (99, 'test_event', current_timestamp)"

docker compose exec -T trino trino --execute \
  "SELECT count(*) AS total FROM iceberg.demo.events"
```

---

### 6. Run Flink SQL streaming job — Iceberg incremental source

This is the **core of the AWS blog architecture**: Flink reads the Iceberg table as a streaming source using incremental snapshot reads. Every time you insert rows via Trino, Flink detects the new snapshot and prints the new rows in real time.

**Start the stack** (first run downloads ~70 MB of Iceberg JARs once):

```bash
docker compose up -d
```

**Submit the job:**

```bash
./scripts/run-flink-iceberg-job.sh
```

**Watch the output** in a second terminal:

```bash
docker compose logs -f flink-taskmanager 2>&1 | grep "+I"
```

**Insert a row** to trigger a real change:

```bash
docker compose exec -T trino trino --execute \
  "INSERT INTO iceberg.demo.events VALUES (200, 'new_event', current_timestamp)"
```

Within ~10 seconds, Flink will detect the new Iceberg snapshot and print the new row:

```
flink-taskmanager  | +I[200, new_event, 2026-06-24T10:30:00]
```

**Cancel the job** via the Flink UI at `http://localhost:8081` when done.

---

### 7. Check Flink checkpoints in MinIO

```bash
docker run --rm --network data-platform \
  -e MC_HOST_local=http://minioadmin:minioadmin@minio:9000 \
  minio/mc ls --recursive local/checkpoints
```

Expected: checkpoint state files stored by Flink during the streaming job.

---

### 8. Verify Prometheus metrics

```bash
curl -fsS "http://localhost:9090/api/v1/query?query=up" | python3 -m json.tool | head -30
```

Expected: status results for `flink-jobmanager` and `flink-taskmanager`.

---

### 9. Full automated smoke test

```bash
./scripts/smoke-test.sh
```

Expected output ends with: `Smoke test passed.`

---

## Reference

- https://aws.amazon.com/blogs/big-data/building-unified-data-pipelines-with-apache-iceberg-and-apache-flink/

