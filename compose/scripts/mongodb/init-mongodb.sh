#!/bin/sh
set -e

echo "==================================================================="
echo "Initializing MongoDB database..."
echo "==================================================================="

MONGO_URI="${MONGO_URI:-mongodb://localhost:27017/}"
DB_NAME="ai-defra-search-knowledge"

echo "Database: ${DB_NAME}"
echo "MongoDB: using --uri (supports TLS, auth, and DocumentDB connection strings)"
echo "==================================================================="

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

if [ ! -f "${DATA_DIR}/documents.json" ]; then
  echo "ERROR: Required file not found: ${DATA_DIR}/documents.json"
  exit 1
fi

echo "Using seed data from: ${DATA_DIR}"

# Import knowledge groups (upsert mode to replace existing)
# Use --uri so TLS, credentials, and tlsCAFile in the URI work (DocumentDB / Atlas).
echo "Importing knowledge groups..."
mongoimport --uri="${MONGO_URI}" \
  --db="${DB_NAME}" --collection="knowledgeGroups" \
  --file="${DATA_DIR}/knowledgeGroups.json" \
  --mode=upsert --upsertFields="_id"
echo "✓ Knowledge groups imported: 1"

echo "Importing documents..."
mongoimport --uri="${MONGO_URI}" \
  --db="${DB_NAME}" --collection="documents" \
  --file="${DATA_DIR}/documents.json" \
  --mode=upsert --upsertFields="_id"
echo "✓ Documents imported: 5"

echo "==================================================================="
echo "MongoDB initialization completed successfully"
echo "==================================================================="
