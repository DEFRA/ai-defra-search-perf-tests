#!/bin/sh
set -e

echo "==================================================================="
echo "Initializing PostgreSQL database..."
echo "==================================================================="
echo "Host: ${POSTGRES_HOST}"
echo "Port: ${POSTGRES_PORT}"
echo "Database: ${POSTGRES_DB}"
echo "User: ${POSTGRES_USER}"
echo "SSL Mode: ${POSTGRES_SSL_MODE:-disable}"
echo "==================================================================="

export PGPASSWORD="${POSTGRES_PASSWORD}"
if [ -n "${POSTGRES_SSL_MODE}" ]; then
  export PGSSLMODE="${POSTGRES_SSL_MODE}"
fi

SCRIPT_DIR=${JM_HOME:-/opt/perftest}/scripts/postgres

if [ ! -d "${SCRIPT_DIR}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

echo "Executing init-database.sql..."
psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
  -v ON_ERROR_STOP=1 \
  -f "${SCRIPT_DIR}/init-database.sql"
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to initialize database schema"
  exit 1
fi

echo "Executing seed-postgres.sql..."
psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
  -v ON_ERROR_STOP=1 \
  -f "${SCRIPT_DIR}/seed-postgres.sql"
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to seed database with test data"
  exit 1
fi

echo "==================================================================="
echo "PostgreSQL initialization completed successfully"
echo "==================================================================="

unset PGPASSWORD
unset PGSSLMODE
