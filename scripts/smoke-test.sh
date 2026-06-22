#!/usr/bin/env bash
set -euo pipefail

# Wait for a URL to answer successfully.
wait_for_url() {
  local name="$1"
  local url="$2"
  local retries=40
  local delay=3

  echo "Waiting for ${name} to be ready..."
  for ((i=1; i<=retries; i++)); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo "${name} is ready."
      return 0
    fi
    sleep "$delay"
  done

  echo "${name} did not become ready in time." >&2
  return 1
}

# Wait until Trino CLI can execute SQL.
wait_for_trino_cli() {
  local retries=40
  local delay=3

  echo "Waiting for Trino CLI..."
  for ((i=1; i<=retries; i++)); do
    if docker compose exec -T trino trino --execute "SELECT 1" >/dev/null 2>&1; then
      echo "Trino CLI is ready."
      return 0
    fi
    sleep "$delay"
  done

  echo "Trino CLI did not become ready in time." >&2
  return 1
}

echo "Starting stack..."
docker compose up -d

wait_for_url "Nessie" "http://localhost:19120/api/v2/config"
wait_for_url "Trino HTTP" "http://localhost:8080/v1/info"
wait_for_trino_cli

echo "Creating Iceberg schema/table and inserting rows..."
docker compose exec -T trino trino --execute "CREATE SCHEMA IF NOT EXISTS iceberg.demo WITH (location='s3://warehouse/demo');"
docker compose exec -T trino trino --execute "CREATE TABLE IF NOT EXISTS iceberg.demo.events (id BIGINT, event_type VARCHAR, created_at TIMESTAMP);"
docker compose exec -T trino trino --execute "INSERT INTO iceberg.demo.events VALUES (1, 'signup', current_timestamp), (2, 'purchase', current_timestamp);"

echo "Querying inserted data..."
docker compose exec -T trino trino --execute "SELECT * FROM iceberg.demo.events ORDER BY id;"

echo "Smoke test passed."


