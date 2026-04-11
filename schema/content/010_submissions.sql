-- Content Table: submissions (updated)
-- Purpose: The actual payload from a source about an entity
-- Change: asset_id → entity_id (FK to entities table)
-- Date: 2026-04-11

BEGIN;

-- This file documents the UPDATED submissions table structure.
-- The actual migration (asset_id → entity_id) is handled by:
--   schema/migrations/000_drop_assets_and_migrate.sql

-- For reference, here's the current submissions table with entity_id:

/*
CREATE TABLE IF NOT EXISTS submissions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id       UUID REFERENCES sources(id) ON DELETE SET NULL,
  entity_id        UUID REFERENCES entities(id) ON DELETE SET NULL,  -- CHANGED from asset_id
  submitted_at    TIMESTAMPTZ DEFAULT NOW(),
  tier            SMALLINT NOT NULL DEFAULT 2 CHECK (tier BETWEEN 1 AND 4),
  category        TEXT NOT NULL,  -- now references categories(name) or stays as TEXT for flexibility
  summary         TEXT,
  content         TEXT,
  r2_keys         TEXT[],
  status          TEXT DEFAULT 'received' CHECK (status IN (
                    'received', 'processing', 'classified',
                    'flagged', 'archived', 'rejected'
                  )),
  usefulness_score SMALLINT,
  meta            JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_submissions_source_id ON submissions(source_id);
CREATE INDEX IF NOT EXISTS idx_submissions_entity_id ON submissions(entity_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON submissions(status);
CREATE INDEX IF NOT EXISTS idx_submissions_category ON submissions(category);
*/

-- Note: If you want to enforce category as a FK to categories table, uncomment below:
-- ALTER TABLE submissions ADD CONSTRAINT submissions_category_fkey
--   FOREIGN KEY (category) REFERENCES categories(name);

COMMIT;
