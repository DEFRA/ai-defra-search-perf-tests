db = db.getSiblingDB('ai-defra-search-knowledge')

print('Clearing MongoDB collections...')

db.knowledgeGroups.deleteMany({})
db.documents.deleteMany({})

print('MongoDB collections cleared successfully')
