/**
 * Mongodb script for inserting test data into the docker-compose mongo instance
 */

// Use the correct database for the data service
db = db.getSiblingDB('ai-defra-search-data')

// Create knowledge group in the knowledgeGroups collection
db.knowledgeGroups.insertOne({
  _id: 'kg_34vf0wr3e06l',
  groupId: 'kg_34vf0wr3e06l',
  title: 'UCD Knowledge Base',
  name: 'UCD Knowledge Base',
  description: 'Test knowledge base for User-Centered Design',
  owner: 'test-user',
  status: 'active',
  activeSnapshot: 'kg_34vf0wr3e06l',
  createdAt: new Date(),
  updatedAt: new Date()
})

print('Created knowledge group: kg_34vf0wr3e06l')

// Create knowledge snapshot in the knowledgeSnapshots collection
// This matches the structure expected by MongoKnowledgeSnapshotRepository
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
})

print('Created knowledge snapshot: kg_34vf0wr3e06l')

// Verify both were created
var groupCount = db.knowledgeGroups.countDocuments({ groupId: 'kg_34vf0wr3e06l' })
var snapshotCount = db.knowledgeSnapshots.countDocuments({ snapshotId: 'kg_34vf0wr3e06l' })
print('Knowledge groups count: ' + groupCount)
print('Knowledge snapshots count: ' + snapshotCount)
