#!/usr/bin/env bash
# ============================================================
# run-flink-iceberg-job.sh
#
# Submits the Iceberg incremental source streaming job to
# the local Flink cluster.
#
# Usage:
#   ./scripts/run-flink-iceberg-job.sh
# ============================================================
set -euo pipefail

echo "Submitting Iceberg incremental source job to Flink..."
docker compose exec -it flink-jobmanager bash -lc '
  export HADOOP_CLASSPATH=$(find /opt/flink-hadoop -name "*.jar" | tr "\n" ":")
  /opt/flink/bin/sql-client.sh -f /opt/flink/jobs/iceberg-source.sql
'

echo ""
echo "========================================="
echo "Job submitted. Monitor new rows with:"
echo "  docker compose logs -f flink-taskmanager 2>&1 | grep '+I'"
echo ""
echo "Insert a row to see the job react:"
echo "  docker compose exec -T trino trino --execute \\"
echo "    \"INSERT INTO iceberg.demo.events VALUES (200, 'new_event', current_timestamp)\""
echo ""
echo "Cancel the job from the Flink UI:"
echo "  http://localhost:8081"
echo "========================================="



