-- Truncate tables to remove existing data before seeding
-- Used in perf-test environments where tables already exist
-- Checks if table exists before truncating to avoid errors in local environment

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'knowledge_vectors') THEN
        TRUNCATE TABLE knowledge_vectors CASCADE;
        RAISE NOTICE 'Truncated knowledge_vectors table';
    ELSE
        RAISE NOTICE 'Table knowledge_vectors does not exist, skipping truncate';
    END IF;
END $$;
