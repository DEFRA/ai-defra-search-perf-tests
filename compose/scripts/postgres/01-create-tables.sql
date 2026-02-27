-- Enable pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

DROP TABLE IF EXISTS knowledge_vectors CASCADE;

CREATE TABLE knowledge_vectors (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding VECTOR(1024),
    snapshot_id VARCHAR(50),
    source_id VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON knowledge_vectors USING hnsw (embedding vector_cosine_ops);
