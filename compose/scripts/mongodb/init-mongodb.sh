#!/bin/sh
set -e

echo "==================================================================="
echo "Initializing MongoDB database..."
echo "==================================================================="

MONGO_URI="${MONGO_URI:-mongodb://localhost:27017/}"

echo "MongoDB URI: ${MONGO_URI}"
echo "Database: ai-defra-search-data"
echo "==================================================================="

# Get the directory where this script is located
SCRIPT_DIR="$(dirname "$0")"

if [ -f "${SCRIPT_DIR}/seed-mongodb.js" ]; then
  SEED_SCRIPT="${SCRIPT_DIR}/seed-mongodb.js"
elif [ -f "/docker-entrypoint-initdb.d/seed-mongodb.js" ]; then
  SEED_SCRIPT="/docker-entrypoint-initdb.d/seed-mongodb.js"
elif [ -f "./seed-mongodb.js" ]; then
  SEED_SCRIPT="./seed-mongodb.js"
else
  echo "ERROR: seed-mongodb.js not found"
  echo "Tried: ${SCRIPT_DIR}/seed-mongodb.js, /docker-entrypoint-initdb.d/seed-mongodb.js, ./seed-mongodb.js"
  exit 1
fi

echo "Using seed script: ${SEED_SCRIPT}"

# In perf-test environment, clear existing data before seeding
if [ "${ENVIRONMENT:-}" = "perf-test" ]; then
  echo "Perf-test environment detected - clearing existing data from collections..."

  # Find clear script using same logic as seed script
  if [ -f "${SCRIPT_DIR}/clear-mongodb.js" ]; then
    CLEAR_SCRIPT="${SCRIPT_DIR}/clear-mongodb.js"
  elif [ -f "/docker-entrypoint-initdb.d/clear-mongodb.js" ]; then
    CLEAR_SCRIPT="/docker-entrypoint-initdb.d/clear-mongodb.js"
  elif [ -f "./clear-mongodb.js" ]; then
    CLEAR_SCRIPT="./clear-mongodb.js"
  else
    echo "ERROR: clear-mongodb.js not found"
    echo "Tried: ${SCRIPT_DIR}/clear-mongodb.js, /docker-entrypoint-initdb.d/clear-mongodb.js, ./clear-mongodb.js"
    exit 1
  fi

  echo "Executing clear-mongodb.js..."
  mongosh "${MONGO_URI}" --quiet --file "${CLEAR_SCRIPT}"

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to clear MongoDB collections"
    exit 1
  fi
fi

echo "Executing seed-mongodb.js..."
mongosh "${MONGO_URI}" --quiet --file "${SEED_SCRIPT}"

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to initialize MongoDB"
  exit 1
fi

echo "==================================================================="
echo "MongoDB initialization completed successfully"
echo "==================================================================="
