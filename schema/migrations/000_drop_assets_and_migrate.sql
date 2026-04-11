-- Migration: assets → entities
-- Purpose: Replace narrow assets table with flexible entities master table
-- Date: 2026-04-11
-- Dependencies: Must run AFTER 003_entities.sql is applied
-- Safety: Idempotent (safe to re-run)

BEGIN;

-- =====================================================
-- STEP 1: Create entities table (if not exists)
-- This should already exist from 003_entities.sql
-- =====================================================

-- Verify entities table exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'entities') THEN
    RAISE EXCEPTION 'entities table does not exist. Run 003_entities.sql first.';
  END IF;
END $$;

-- =====================================================
-- STEP 2: Migrate existing assets → entities
-- Only runs if assets table has data
-- =====================================================

DO $$
DECLARE
  asset_count INT;
BEGIN
  -- Check if assets table exists and has rows
  SELECT COUNT(*) INTO asset_count
  FROM information_schema.tables
  WHERE table_name = 'assets';

  IF asset_count > 0 THEN
    -- Check if there's actual data
    EXECUTE 'SELECT COUNT(*) FROM assets' INTO asset_count;

    IF asset_count > 0 THEN
      RAISE NOTICE 'Migrating % assets records to entities...', asset_count;

      -- Insert assets into entities with type mapping
      INSERT INTO entities (id, source_id, name, entity_type, description, ecosystem, stage, meta, created_at, updated_at)
      SELECT
        id,
        source_id,
        name,
        CASE asset_type
          WHEN 'agent' THEN 'tool'
          WHEN 'project' THEN 'project'
          WHEN 'workflow' THEN 'tool'
          WHEN 'guide' THEN 'documentation'
          WHEN 'dataset' THEN 'tool'
          WHEN 'incident' THEN 'event'
          WHEN 'tool' THEN 'tool'
          WHEN 'strategy' THEN 'documentation'
          ELSE 'tool'  -- fallback
        END,
        description,
        ecosystem,
        stage,
        meta,
        created_at,
        updated_at
      FROM assets
      ON CONFLICT (id) DO NOTHING;  -- skip if entity already exists with same ID

      RAISE NOTICE 'Migration complete. % records migrated.', asset_count;
    ELSE
      RAISE NOTICE 'assets table exists but is empty. Skipping data migration.';
    END IF;
  ELSE
    RAISE NOTICE 'assets table does not exist. Skipping migration.';
  END IF;
END $$;

-- =====================================================
-- STEP 3: Update FK references in submissions
-- =====================================================

DO $$
BEGIN
  -- Check if submissions.asset_id column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'submissions' AND column_name = 'asset_id'
  ) THEN
    RAISE NOTICE 'Updating submissions.asset_id → entity_id...';

    -- Drop old FK constraint if it exists
    ALTER TABLE submissions DROP CONSTRAINT IF EXISTS submissions_asset_id_fkey;

    -- Rename column
    ALTER TABLE submissions RENAME COLUMN asset_id TO entity_id;

    -- Add new FK constraint
    ALTER TABLE submissions ADD CONSTRAINT submissions_entity_id_fkey
      FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE SET NULL;

    -- Create index on new column
    CREATE INDEX IF NOT EXISTS idx_submissions_entity_id ON submissions(entity_id);

    RAISE NOTICE 'submissions.entity_id updated successfully.';
  ELSE
    RAISE NOTICE 'submissions.entity_id already exists. Skipping.';
  END IF;
END $$;

-- =====================================================
-- STEP 4: Update FK references in suggestion_outcomes
-- =====================================================

DO $$
BEGIN
  -- Check if suggestion_outcomes table exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name = 'suggestion_outcomes'
  ) THEN
    RAISE NOTICE 'suggestion_outcomes table does not exist. Skipping.';
  ELSE

  -- Check if target_asset_id column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'suggestion_outcomes' AND column_name = 'target_asset_id'
  ) THEN
    RAISE NOTICE 'Updating suggestion_outcomes.target_asset_id → target_entity_id...';

    -- Drop old FK constraint if it exists
    ALTER TABLE suggestion_outcomes DROP CONSTRAINT IF EXISTS suggestion_outcomes_target_asset_id_fkey;

    -- Rename column
    ALTER TABLE suggestion_outcomes RENAME COLUMN target_asset_id TO target_entity_id;

    -- Add new FK constraint
    ALTER TABLE suggestion_outcomes ADD CONSTRAINT suggestion_outcomes_target_entity_id_fkey
      FOREIGN KEY (target_entity_id) REFERENCES entities(id) ON DELETE SET NULL;

    -- Create index on new column
    CREATE INDEX IF NOT EXISTS idx_suggestion_outcomes_target_entity_id ON suggestion_outcomes(target_entity_id);

    RAISE NOTICE 'suggestion_outcomes.target_entity_id updated successfully.';
  ELSE
    RAISE NOTICE 'suggestion_outcomes.target_entity_id already exists. Skipping.';
  END IF;
  END IF;
END $$;

-- =====================================================
-- STEP 5: Drop assets table
-- =====================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'assets') THEN
    RAISE NOTICE 'Dropping assets table...';
    DROP TABLE IF EXISTS assets CASCADE;
    RAISE NOTICE 'assets table dropped.';
  ELSE
    RAISE NOTICE 'assets table does not exist. Nothing to drop.';
  END IF;
END $$;

-- =====================================================
-- STEP 6: Verify migration
-- =====================================================

DO $$
DECLARE
  entity_count INT;
  submission_entity_count INT;
BEGIN
  SELECT COUNT(*) INTO entity_count FROM entities;
  SELECT COUNT(*) INTO submission_entity_count FROM submissions WHERE entity_id IS NOT NULL;

  RAISE NOTICE 'Migration verification:';
  RAISE NOTICE '  Total entities: %', entity_count;
  RAISE NOTICE '  Submissions with entity_id: %', submission_entity_count;

  IF entity_count = 0 THEN
    RAISE WARNING 'WARNING: entities table is empty after migration!';
  END IF;
END $$;

COMMIT;
