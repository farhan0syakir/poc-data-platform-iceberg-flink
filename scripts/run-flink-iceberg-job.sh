#!/usr/bin/env bash
set -euo pipefail

SQL_FILE_IN_CONTAINER="${1:-/opt/flink/jobs/iceberg-source.sql}"

echo "Checking Flink JobManager availability..."
docker compose exec -T flink-jobmanager true >/dev/null

echo "Validating SQL file exists: ${SQL_FILE_IN_CONTAINER}"
docker compose exec -T flink-jobmanager test -f "${SQL_FILE_IN_CONTAINER}"

echo "Submitting SQL job: ${SQL_FILE_IN_CONTAINER}"
docker compose exec -T flink-jobmanager bash -lc '
  export HADOOP_CLASSPATH=$(find /opt/flink-hadoop -name "*.jar" | tr "\n" ":")
  /opt/flink/bin/sql-client.sh -f "'"${SQL_FILE_IN_CONTAINER}"'"
'
