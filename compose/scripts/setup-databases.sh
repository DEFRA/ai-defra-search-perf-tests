#!/bin/sh
set -e

echo "==================================================================="
echo "Seeding databases..."
echo "==================================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export ENVIRONMENT="${ENVIRONMENT:-local}"
export POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_DB="${POSTGRES_DB:-ai_defra_search_knowledge}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-ppp}"
export POSTGRES_SSL_MODE="${POSTGRES_SSL_MODE:-disable}"
export MONGO_URI="${MONGO_URI:-mongodb://localhost:27017/}"

echo "Environment: ${ENVIRONMENT}"
echo "PostgreSQL: ${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
if [ -n "${MONGO_URI}" ]; then
  echo "MongoDB: MONGO_URI is set (${#MONGO_URI} chars — not printed; use full URI with TLS params for DocumentDB)"
else
  echo "MongoDB: MONGO_URI is unset (will use init-mongodb.sh default)"
fi
echo "==================================================================="

echo "Initializing PostgreSQL..."
${SCRIPT_DIR}/postgres/init-postgres.sh

if [ $? -ne 0 ]; then
  echo "ERROR: PostgreSQL initialization failed"
  exit 1
fi

echo "Initializing MongoDB..."
${SCRIPT_DIR}/mongodb/init-mongodb.sh

if [ $? -ne 0 ]; then
  echo "ERROR: MongoDB initialization failed"
  exit 1
fi

echo "==================================================================="
echo "All databases seeded successfully!"
echo "==================================================================="
