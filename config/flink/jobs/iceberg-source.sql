-- ============================================================
-- Flink SQL: Iceberg Incremental Source (Nessie + MinIO)
--
-- This job reads the Iceberg `events` table as a streaming
-- source using incremental snapshot reads.
--
-- Each INSERT via Trino creates a new Iceberg snapshot.
-- Flink detects new snapshots every 10 seconds and prints
-- only the newly added rows.
--
-- Submit:
--   ./scripts/run-flink-iceberg-job.sh
--
-- Watch output:
--   docker compose logs -f flink-taskmanager 2>&1 | grep "+I"
--
-- Insert a row to trigger a change:
--   docker compose exec -T trino trino --execute \
--     "INSERT INTO iceberg.demo.events VALUES (200, 'new_event', current_timestamp)"
-- ============================================================

-- Create Nessie-backed Iceberg catalog pointing at MinIO
CREATE CATALOG nessie_catalog WITH (
  'type'                    = 'iceberg',
  'catalog-impl'            = 'org.apache.iceberg.nessie.NessieCatalog',
  'uri'                     = 'http://nessie:19120/api/v2',
  'ref'                     = 'main',
  'warehouse'               = 's3://warehouse',
  'io-impl'                 = 'org.apache.iceberg.aws.s3.S3FileIO',
  's3.endpoint'             = 'http://minio:9000',
  's3.path-style-access'    = 'true',
  's3.access-key-id'        = 'minioadmin',
  's3.secret-access-key'    = 'minioadmin',
  's3.region'               = 'us-east-1'
);

USE CATALOG nessie_catalog;
USE demo;

-- Sink: print connector writes to TaskManager stdout (container logs)
CREATE TEMPORARY TABLE events_print (
  id          BIGINT,
  event_type  STRING,
  created_at  TIMESTAMP(6)
) WITH (
  'connector' = 'print'
);

-- Stream: read Iceberg incrementally, emit each new row
INSERT INTO events_print
SELECT id, event_type, created_at
FROM events
/*+ OPTIONS('streaming' = 'true', 'monitor-interval' = '10s') */;


