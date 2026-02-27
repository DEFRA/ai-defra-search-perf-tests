#!/bin/sh
set -e

echo "==================================================================="
echo "Initializing MongoDB database..."
echo "==================================================================="

MONGO_URI="${MONGO_URI:-mongodb://localhost:27017/}"
DB_NAME="ai-defra-search-data"

echo "MongoDB URI: ${MONGO_URI}"
echo "Database: ${DB_NAME}"
echo "==================================================================="

# Extract host and port from MONGO_URI
MONGO_HOST=$(echo "$MONGO_URI" | sed 's|mongodb://||' | sed 's|/.*||' | cut -d: -f1)
MONGO_PORT=$(echo "$MONGO_URI" | sed 's|mongodb://||' | sed 's|/.*||' | cut -d: -f2)
MONGO_PORT=${MONGO_PORT:-27017}

echo "MongoDB Host: ${MONGO_HOST}"
echo "MongoDB Port: ${MONGO_PORT}"

TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

# Create knowledge groups JSON file
cat > "${TEMP_DIR}/knowledgeGroups.json" << 'EOFKG'
{
  "_id": "kg_34vf0wr3e06l",
  "groupId": "kg_34vf0wr3e06l",
  "title": "UCD Knowledge Base",
  "description": "Test knowledge base for User-Centered Design",
  "owner": "test-user",
  "activeSnapshot": "kg_34vf0wr3e06l",
  "createdAt": { "$date": "2026-02-27T00:00:00.000Z" },
  "updatedAt": { "$date": "2026-02-27T00:00:00.000Z" }
}
EOFKG

# Create knowledge snapshots JSON file
cat > "${TEMP_DIR}/knowledgeSnapshots.json" << 'EOFKS'
{
  "snapshotId": "kg_34vf0wr3e06l",
  "groupId": "kg_34vf0wr3e06l",
  "version": 1,
  "createdAt": { "$date": "2026-02-27T00:00:00.000Z" },
  "sources": [
    {
      "sourceId": "doc_001",
      "name": "What is UCD",
      "location": "test-data",
      "sourceType": "BLOB"
    },
    {
      "sourceId": "doc_002",
      "name": "UCD Good Practice",
      "location": "test-data",
      "sourceType": "BLOB"
    },
    {
      "sourceId": "doc_003",
      "name": "Defra and UCD",
      "location": "test-data",
      "sourceType": "BLOB"
    },
    {
      "sourceId": "doc_004",
      "name": "Accessibility in UCD",
      "location": "test-data",
      "sourceType": "BLOB"
    },
    {
      "sourceId": "doc_005",
      "name": "Defra Service Standards",
      "location": "test-data",
      "sourceType": "BLOB"
    }
  ]
}
EOFKS

# Import knowledge groups (upsert mode to replace existing)
echo "Importing knowledge groups..."
mongoimport --host="${MONGO_HOST}" --port="${MONGO_PORT}" \
  --db="${DB_NAME}" --collection="knowledgeGroups" \
  --file="${TEMP_DIR}/knowledgeGroups.json" \
  --mode=upsert --upsertFields="_id"

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to import knowledge groups"
  exit 1
fi
echo "✓ Knowledge groups imported: 1"

# Import knowledge snapshots (upsert mode to replace existing)
echo "Importing knowledge snapshots..."
mongoimport --host="${MONGO_HOST}" --port="${MONGO_PORT}" \
  --db="${DB_NAME}" --collection="knowledgeSnapshots" \
  --file="${TEMP_DIR}/knowledgeSnapshots.json" \
  --mode=upsert --upsertFields="snapshotId"

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to import knowledge snapshots"
  exit 1
fi
echo "✓ Knowledge snapshots imported: 1"

echo "==================================================================="
echo "MongoDB initialization completed successfully"
echo "==================================================================="
