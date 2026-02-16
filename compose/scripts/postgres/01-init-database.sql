-- Initialize PostgreSQL database for AI DEFRA Search performance tests
-- This script runs automatically via /docker-entrypoint-initdb.d/

-- Enable pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Create knowledge_vectors table with all required columns
CREATE TABLE knowledge_vectors (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding VECTOR(1024),
    snapshot_id VARCHAR(50),
    source_id VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create HNSW index for efficient vector similarity search
CREATE INDEX ON knowledge_vectors USING hnsw (embedding vector_cosine_ops);
