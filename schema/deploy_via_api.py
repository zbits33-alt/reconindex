#!/usr/bin/env python3
"""
Deploy Phase 1 schema to Supabase via REST API.
Reads SQL files and executes them using psql-like approach.
Since Supabase REST API doesn't support raw SQL, we'll provide manual instructions.
"""

import os
from pathlib import Path

SUPABASE_URL = "https://nygdcvjmjzvyxljexjjo.supabase.co"
SQL_DIR = Path("/home/agent/workspace/schema")

# SQL files in execution order
SQL_FILES = [
    "core/003_entities.sql",
    "core/004_entity_profiles.sql",
    "core/005_entity_relationships.sql",
    "taxonomy/006_classification_types.sql",
    "taxonomy/007_categories.sql",
    "taxonomy/008_tags.sql",
    "taxonomy/020_entity_classifications.sql",
    "content/010_submissions.sql",
    "content/013_content_items.sql",
    "content/014_ecosystem_updates.sql",
]

MIGRATION_FILE = "migrations/000_drop_assets_and_migrate.sql"

def main():
    print("="*70)
    print("PHASE 1 SCHEMA DEPLOYMENT INSTRUCTIONS")
    print("="*70)
    print(f"\nProject: {SUPABASE_URL}")
    print(f"Dashboard: https://app.supabase.com/project/nygdcvjmjzvyxljexjjo/sql\n")

    print("METHOD 1: Supabase Dashboard (Recommended)")
    print("-" * 70)
    print("""
1. Go to: https://app.supabase.com/project/nygdcvjmjzvyxljexjjo/sql
2. Click "New Query"
3. For each file below:
   a. Copy the entire contents of the file
   b. Paste into the SQL Editor
   c. Click "Run" (or Ctrl+Enter / Cmd+Enter)
   d. Wait for success message
   e. Proceed to next file

IMPORTANT: Execute files in the exact order listed below.
""")

    print("\nFile Execution Order:")
    print("-" * 70)
    for i, sql_file in enumerate(SQL_FILES, 1):
        filepath = SQL_DIR / sql_file
        size = filepath.stat().st_size if filepath.exists() else 0
        print(f"{i:2d}. {sql_file:<50s} ({size:>6,} bytes)")

    print(f"\n{len(SQL_FILES)+1:2d}. {MIGRATION_FILE:<50s} (CRITICAL - runs last)")

    print("\n" + "="*70)
    print("VERIFICATION QUERIES")
    print("="*70)
    print("""
After all files are executed, run these queries to verify success:

-- 1. Check entities table exists
SELECT COUNT(*) AS entity_count FROM entities;

-- 2. Verify assets table is gone (should return FALSE)
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_name = 'assets'
) AS assets_exists;

-- 3. Check submissions.entity_id column exists
SELECT column_name FROM information_schema.columns
WHERE table_name = 'submissions' AND column_name = 'entity_id';

-- 4. Check taxonomy tables are seeded
SELECT COUNT(*) AS category_count FROM categories;
SELECT COUNT(*) AS classification_type_count FROM classification_types;

-- 5. List all new tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'entities', 'entity_profiles', 'entity_relationships',
    'classification_types', 'categories', 'tags',
    'entity_classifications', 'entity_tags', 'knowledge_unit_tags',
    'content_items', 'ecosystem_updates'
  )
ORDER BY table_name;
""")

    print("\n" + "="*70)
    print("ROLLBACK PLAN (if something goes wrong)")
    print("="*70)
    print("""
If migration fails or causes issues, run this in SQL Editor:

BEGIN;

-- Recreate assets table from entities (reverse migration)
CREATE TABLE IF NOT EXISTS assets AS
SELECT
  id, source_id, name,
  CASE entity_type
    WHEN 'tool' THEN 'agent'
    WHEN 'project' THEN 'project'
    WHEN 'documentation' THEN 'guide'
    WHEN 'event' THEN 'incident'
    ELSE 'tool'
  END AS asset_type,
  description, ecosystem, stage, meta, created_at, updated_at
FROM entities;

-- Restore submissions.asset_id
ALTER TABLE submissions RENAME COLUMN IF EXISTS entity_id TO asset_id;

-- Drop new tables
DROP TABLE IF EXISTS entity_profiles CASCADE;
DROP TABLE IF EXISTS entity_relationships CASCADE;
DROP TABLE IF EXISTS entity_classifications CASCADE;
DROP TABLE IF EXISTS classification_types CASCADE;
DROP TABLE IF EXISTS entity_tags CASCADE;
DROP TABLE IF EXISTS content_items CASCADE;
DROP TABLE IF EXISTS ecosystem_updates CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS knowledge_unit_tags CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS entities CASCADE;

COMMIT;
""")

    print("\n" + "="*70)
    print("NEXT STEPS AFTER SUCCESSFUL DEPLOYMENT")
    print("="*70)
    print("""
1. ✅ All verification queries pass
2. Update Cloudflare Worker API (add /entities, /content-items endpoints)
3. Update Recon intelligence filter (handle new entity types)
4. Update frontend (make reconindex.com dynamic)
5. Seed initial entity profiles (Predator, QuantX, DKTrenchBot)
""")

if __name__ == "__main__":
    main()
