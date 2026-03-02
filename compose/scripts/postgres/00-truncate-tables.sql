-- Truncate tables to remove existing data before seeding
-- Used in perf-test environments where tables already exist
-- Checks if table exists before truncating to avoid errors in local environment

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = current_schema() AND table_name = 'knowledge_vectors') THEN
        TRUNCATE TABLE knowledge_vectors CASCADE;
        RAISE NOTICE 'Truncated knowledge_vectors table';
    ELSE
        RAISE NOTICE 'Table knowledge_vectors does not exist in schema %, skipping truncate', current_schema();
    END IF;
END $$;
