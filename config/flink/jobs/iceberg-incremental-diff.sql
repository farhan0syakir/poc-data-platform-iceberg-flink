-- Flink SQL job: one-time incremental read between two Iceberg snapshots.
-- Replace <START_SNAPSHOT_ID> and <END_SNAPSHOT_ID> before running.

CREATE CATALOG nessie_catalog WITH (
  'type' = 'iceberg',
  'catalog-impl' = 'org.apache.iceberg.nessie.NessieCatalog',
  'uri' = 'http://nessie:19120/api/v2',
  'ref' = 'main',
  'warehouse' = 's3://warehouse',
  'io-impl' = 'org.apache.iceberg.aws.s3.S3FileIO',
  's3.endpoint' = 'http://minio:9000',
  's3.path-style-access' = 'true',
  's3.access-key-id' = 'minioadmin',
  's3.secret-access-key' = 'minioadmin',
  's3.region' = 'us-east-1'
);

USE CATALOG nessie_catalog;
CREATE DATABASE IF NOT EXISTS demo;
USE demo;

CREATE TEMPORARY TABLE events_diff_print (
  id BIGINT,
  event_type STRING,
  created_at TIMESTAMP(6)
) WITH (
  'connector' = 'print'
);

SET 'execution.runtime-mode' = 'batch';

INSERT INTO events_diff_print
SELECT id, event_type, created_at
FROM events /*+ OPTIONS(
  'start-snapshot-id'='<START_SNAPSHOT_ID>',
  'end-snapshot-id'='<END_SNAPSHOT_ID>'
) */;
