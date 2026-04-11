# Schema Deployment Order

> Execute these SQL files in order on your Supabase project.
> Each file is idempotent (safe to re-run).

---

## Phase 1: Core Tables

Run these first — they create the foundation.

```bash
# 1. Sources (already exists, but included for completeness)
psql -f core/001_sources.sql

# 2. Permissions (already exists)
psql -f core/002_permissions.sql

# 3. Entities (NEW — replaces assets)
psql -f core/003_entities.sql

# 4. Entity Profiles (NEW)
psql -f core/004_entity_profiles.sql

# 5. Entity Relationships (NEW)
psql -f core/005_entity_relationships.sql
```

---

## Phase 2: Taxonomy Tables

Controlled vocabularies and tag systems.

```bash
# 6. Classification Types (NEW — seed with default types)
psql -f taxonomy/006_classification_types.sql

# 7. Categories (NEW — seed with existing categories)
psql -f taxonomy/007_categories.sql

# 8. Tags (NEW — proper tag taxonomy)
psql -f taxonomy/008_tags.sql

# 9. Entity Classifications (NEW — junction table)
psql -f taxonomy/020_entity_classifications.sql

# 10. Entity Tags (part of 008_tags.sql — already created)
# 11. Knowledge Unit Tags (part of 008_tags.sql — already created)
```

---

## Phase 3: Content Tables

Browseable content layer and ecosystem updates.

```bash
# 12. Submissions (UPDATED — documents entity_id change)
psql -f content/010_submissions.sql

# 13. Knowledge Units (already exists, no changes needed)
# (skip — no new file needed)

# 14. Library Candidates (already exists, no changes needed)
# (skip — no new file needed)

# 15. Content Items (NEW)
psql -f content/013_content_items.sql

# 16. Ecosystem Updates (NEW)
psql -f content/014_ecosystem_updates.sql
```

---

## Phase 4: Migration

**CRITICAL:** Run this AFTER all tables above are created.

```bash
# 17. Migrate assets → entities
psql -f migrations/000_drop_assets_and_migrate.sql
```

This script:
1. Verifies `entities` table exists
2. Migrates existing `assets` records → `entities` with type mapping
3. Updates `submissions.asset_id` → `entity_id`
4. Updates `suggestion_outcomes.target_asset_id` → `target_entity_id`
5. Drops `assets` table
6. Verifies migration success

---

## Phase 5: Tracking Tables (Already Exist)

These tables already exist from the Phase 2A migration. No action needed unless you're starting fresh.

```bash
# Already deployed via scripts/migrations/phase2a_migration.sql:
# - knowledge_gaps
# - suggestion_outcomes
# - agent_trust_scores
# - source_maturity
```

If you need to recreate them from scratch, use the files in `schema/tracking/` (to be created in Phase 2).

---

## Verification

After deployment, run these checks:

```sql
-- 1. Verify entities table exists and has data
SELECT COUNT(*) AS entity_count FROM entities;

-- 2. Verify assets table is gone
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_name = 'assets'
) AS assets_exists;  -- should be FALSE

-- 3. Verify submissions.entity_id FK works
SELECT COUNT(*) AS submissions_with_entity
FROM submissions WHERE entity_id IS NOT NULL;

-- 4. Verify taxonomy tables are seeded
SELECT COUNT(*) AS category_count FROM categories;
SELECT COUNT(*) AS classification_type_count FROM classification_types;

-- 5. Verify content tables exist
SELECT COUNT(*) AS content_item_count FROM content_items;
SELECT COUNT(*) AS ecosystem_update_count FROM ecosystem_updates;
```

---

## Rollback Plan

If something goes wrong during migration:

```sql
BEGIN;

-- 1. Recreate assets table from entities (reverse migration)
CREATE TABLE assets AS
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
FROM entities
WHERE source_id IS NOT NULL;  -- only migrate entities that came from sources

-- 2. Restore submissions.asset_id
ALTER TABLE submissions RENAME COLUMN entity_id TO asset_id;
ALTER TABLE submissions ADD CONSTRAINT submissions_asset_id_fkey
  FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE SET NULL;

-- 3. Drop entities and related tables
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
```

**Warning:** This rollback loses any data created in the new tables (profiles, relationships, classifications, content items, ecosystem updates). Only use if migration fails catastrophically.

---

## Next Steps After Deployment

1. **Update Cloudflare Worker API** — add endpoints for `/entities`, `/content-items`, `/ecosystem-updates`
2. **Update Recon intelligence filter** — handle new entity types in auto-classification
3. **Update frontend** — make reconindex.com dynamic, fetch from new APIs
4. **Seed initial data** — create entity profiles for known projects (Predator, QuantX, DKTrenchBot)

---

*Deployment order document lives at: `/home/agent/workspace/schema/DEPLOYMENT_ORDER.md`*
