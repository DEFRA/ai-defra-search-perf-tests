#!/bin/sh
set -e

echo "==================================================================="
echo "Initializing MongoDB database..."
echo "==================================================================="

MONGO_URI="${MONGO_URI:-mongodb://localhost:27017/}"

echo "MongoDB URI: ${MONGO_URI}"
echo "Database: ai-defra-search-data"
echo "==================================================================="

SCRIPT_DIR=${JM_HOME:-/opt/perftest}/scripts/mongodb

# If running from docker-entrypoint-initdb.d, use the current directory
if [ ! -d "${SCRIPT_DIR}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

echo "Executing seed-mongodb.js..."
mongosh "${MONGO_URI}" --quiet --file "${SCRIPT_DIR}/seed-mongodb.js"

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to initialize MongoDB"
  exit 1
fi

echo "==================================================================="
echo "MongoDB initialization completed successfully"
echo "==================================================================="
