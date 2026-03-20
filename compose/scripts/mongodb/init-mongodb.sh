#!/bin/sh
set -e

echo "==================================================================="
echo "Initializing MongoDB database..."
echo "==================================================================="

MONGO_URI="${MONGO_URI:-mongodb://localhost:27017/}"
DB_NAME="ai-defra-search-knowledge"

echo "MongoDB URI: ${MONGO_URI}"
echo "Database: ${DB_NAME}"
echo "==================================================================="

# Extract host and port from MONGO_URI
MONGO_HOST=$(echo "$MONGO_URI" | sed 's|mongodb://||' | sed 's|/.*||' | cut -d: -f1)
MONGO_PORT=$(echo "$MONGO_URI" | sed 's|mongodb://||' | sed 's|/.*||' | cut -d: -f2)
MONGO_PORT=${MONGO_PORT:-27017}

echo "MongoDB Host: ${MONGO_HOST}"
echo "MongoDB Port: ${MONGO_PORT}"

# Determine the data directory location
# When run from MongoDB Docker entrypoint, the mount point is /docker-entrypoint-initdb.d/
# When run directly, use the script's own directory
if [ -d "/docker-entrypoint-initdb.d/data" ]; then
  DATA_DIR="/docker-entrypoint-initdb.d/data"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  DATA_DIR="${SCRIPT_DIR}/data"
fi

# Validate that required JSON files exist
if [ ! -f "${DATA_DIR}/knowledgeGroups.json" ]; then
  echo "ERROR: Required file not found: ${DATA_DIR}/knowledgeGroups.json"
  exit 1
fi

if [ ! -f "${DATA_DIR}/knowledgeSnapshots.json" ]; then
  echo "ERROR: Required file not found: ${DATA_DIR}/knowledgeSnapshots.json"
  exit 1
fi

echo "Using seed data from: ${DATA_DIR}"

# Import knowledge groups (upsert mode to replace existing)
echo "Importing knowledge groups..."
mongoimport --host="${MONGO_HOST}" --port="${MONGO_PORT}" \
  --db="${DB_NAME}" --collection="knowledgeGroups" \
  --file="${DATA_DIR}/knowledgeGroups.json" \
  --mode=upsert --upsertFields="_id"

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to import knowledge groups"
  exit 1
fi
echo "✓ Knowledge groups imported: 1"

echo "Importing knowledge snapshots..."
mongoimport --host="${MONGO_HOST}" --port="${MONGO_PORT}" \
  --db="${DB_NAME}" --collection="knowledgeSnapshots" \
  --file="${DATA_DIR}/knowledgeSnapshots.json" \
  --mode=upsert --upsertFields="snapshotId"

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to import knowledge snapshots"
  exit 1
fi
echo "✓ Knowledge snapshots imported: 1"

echo "==================================================================="
echo "MongoDB initialization completed successfully"
echo "==================================================================="
