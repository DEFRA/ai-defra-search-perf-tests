#!/bin/bash
set -e

echo "Waiting for MongoDB to be ready..."
until mongosh --host mongodb --eval "db.hello().ok" --quiet > /dev/null 2>&1; do
  echo "MongoDB not ready yet, waiting..."
  sleep 2
done

echo "MongoDB is ready. Seeding data..."

# Seed MongoDB with knowledge group and snapshot
mongosh --host mongodb ai-defra-search-data --quiet <<EOF
// Create knowledge group with ALL required fields
db.knowledgeGroups.deleteMany({groupId: 'kg_34vf0wr3e06l'});
db.knowledgeGroups.insertOne({
  _id: 'kg_34vf0wr3e06l',
  groupId: 'kg_34vf0wr3e06l',
  title: 'UCD Knowledge Base',
  description: 'Test knowledge base for User-Centered Design',
  owner: 'test-user',
  activeSnapshot: 'kg_34vf0wr3e06l',
  createdAt: new Date(),
  updatedAt: new Date()
});

// Create knowledge snapshot
db.knowledgeSnapshots.deleteMany({snapshotId: 'kg_34vf0wr3e06l'});
db.knowledgeSnapshots.insertOne({
  snapshotId: 'kg_34vf0wr3e06l',
  groupId: 'kg_34vf0wr3e06l',
  version: 1,
  createdAt: new Date(),
  sources: [
    {
      sourceId: 'doc_001',
      name: 'What is UCD',
      location: 'test-data',
      sourceType: 'BLOB'
    },
    {
      sourceId: 'doc_002',
      name: 'UCD Good Practice',
      location: 'test-data',
      sourceType: 'BLOB'
    },
    {
      sourceId: 'doc_003',
      name: 'Defra and UCD',
      location: 'test-data',
      sourceType: 'BLOB'
    },
    {
      sourceId: 'doc_004',
      name: 'Accessibility in UCD',
      location: 'test-data',
      sourceType: 'BLOB'
    },
    {
      sourceId: 'doc_005',
      name: 'Defra Service Standards',
      location: 'test-data',
      sourceType: 'BLOB'
    }
  ]
});

// Verify
var groupCount = db.knowledgeGroups.countDocuments({groupId: 'kg_34vf0wr3e06l'});
var snapshotCount = db.knowledgeSnapshots.countDocuments({snapshotId: 'kg_34vf0wr3e06l'});
print('Knowledge groups seeded: ' + groupCount);
print('Knowledge snapshots seeded: ' + snapshotCount);
EOF

echo ""
echo "MongoDB seeding complete!"
echo "  - Knowledge group: kg_34vf0wr3e06l"
echo "  - Knowledge snapshot: kg_34vf0wr3e06l"
