#!/bin/sh
set -e

echo "==================================================================="
echo "Seeding databases..."
echo "==================================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_DB="${POSTGRES_DB:-ai_defra_search_data}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-ppp}"
export POSTGRES_SSL_MODE="${POSTGRES_SSL_MODE:-disable}"
export MONGO_URI="${MONGO_URI:-mongodb://localhost:27017/}"

echo "PostgreSQL: ${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
echo "MongoDB: ${MONGO_URI}"
echo "==================================================================="

echo "Initializing PostgreSQL..."
${SCRIPT_DIR}/postgres/init-postgres.sh \
  "${SCRIPT_DIR}/postgres/01-create-tables.sql" \
  "${SCRIPT_DIR}/postgres/02-seed-postgres.sql"

if [ $? -ne 0 ]; then
  echo "ERROR: PostgreSQL initialization failed"
  exit 1
fi

echo "Initializing MongoDB..."
${SCRIPT_DIR}/mongodb/init-mongodb.sh "${SCRIPT_DIR}/mongodb/seed-mongodb.js"

if [ $? -ne 0 ]; then
  echo "ERROR: MongoDB initialization failed"
  exit 1
fi

echo "==================================================================="
echo "All databases seeded successfully!"
echo "==================================================================="
