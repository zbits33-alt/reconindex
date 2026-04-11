# Staging Setup Guide

> Test the schema migration on a free Supabase staging project before deploying to production.

---

## Step 1: Create Staging Supabase Project

1. Go to [supabase.com](https://supabase.com) and log in
2. Click **"New Project"**
3. Fill in:
   - **Name:** `reconindex-staging` (or similar)
   - **Database Password:** Generate a strong password, save it
   - **Region:** Choose closest to you (e.g., US East, EU West)
   - **Pricing Plan:** Free tier (perfect for testing)
4. Click **"Create new project"** — takes ~2 minutes

---

## Step 2: Get Connection Details

After project is created:

1. Go to **Project Settings** → **Database**
2. Copy these values:
   - **Host:** `db.<project-ref>.supabase.co`
   - **Port:** `5432`
   - **Database:** `postgres`
   - **User:** `postgres`
   - **Password:** (the one you set during creation)

3. Also copy the **Connection String** (URI format):
   ```
   postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres
   ```

---

## Step 3: Install psql (if not already installed)

### macOS
```bash
brew install libpq
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install postgresql-client
```

### Linux (Fedora/RHEL)
```bash
sudo dnf install postgresql
```

### Verify installation
```bash
psql --version
# Should output: psql (PostgreSQL) 14.x or higher
```

---

## Step 4: Apply Base Schema (Existing Tables)

Before running our new SQL files, you need the existing tables that our schema depends on:

### Option A: Use Existing Production Schema as Reference

If you have access to the production Supabase project, dump the schema:

```bash
# From production project
pg_dump -h db.<prod-ref>.supabase.co -U postgres -d postgres --schema-only > prod_schema.sql

# Restore to staging
psql "postgresql://postgres:<password>@db.<staging-ref>.supabase.co:5432/postgres" -f prod_schema.sql
```

### Option B: Manually Create Dependencies

If you don't have production access, create the minimal required tables:

```sql
-- Run this in Supabase SQL Editor on staging project

-- Sources table (simplified)
CREATE TABLE IF NOT EXISTS sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  owner TEXT,
  ecosystem TEXT[],
  api_token TEXT UNIQUE NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  meta JSONB DEFAULT '{}'
);

-- Permissions table (simplified)
CREATE TABLE IF NOT EXISTS permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID REFERENCES sources(id) ON DELETE CASCADE,
  default_tier SMALLINT NOT NULL DEFAULT 2,
  allow_logs BOOLEAN DEFAULT FALSE,
  allow_screenshots BOOLEAN DEFAULT FALSE,
  allow_code BOOLEAN DEFAULT FALSE,
  allow_prompts BOOLEAN DEFAULT FALSE,
  allow_configs BOOLEAN DEFAULT FALSE,
  allow_perf_data BOOLEAN DEFAULT FALSE,
  allow_anonymized_sharing BOOLEAN DEFAULT TRUE,
  allow_library_promotion BOOLEAN DEFAULT FALSE,
  never_store TEXT[],
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Submissions table (with asset_id — will be migrated to entity_id)
CREATE TABLE IF NOT EXISTS submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID REFERENCES sources(id) ON DELETE SET NULL,
  asset_id UUID,  -- Will be renamed to entity_id by migration
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  tier SMALLINT NOT NULL DEFAULT 2,
  category TEXT NOT NULL,
  summary TEXT,
  content TEXT,
  r2_keys TEXT[],
  status TEXT DEFAULT 'received',
  usefulness_score SMALLINT,
  meta JSONB DEFAULT '{}'
);

-- Knowledge units table (simplified)
CREATE TABLE IF NOT EXISTS knowledge_units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID,
  source_id UUID,
  tier SMALLINT NOT NULL,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  key_insight TEXT NOT NULL,
  tags TEXT[],
  usefulness_score SMALLINT,
  repeat_count INT DEFAULT 1,
  library_candidate BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Suggestion outcomes table (from Phase 2A)
CREATE TABLE IF NOT EXISTS suggestion_outcomes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  suggestion_id UUID,
  source_id UUID REFERENCES sources(id) ON DELETE CASCADE,
  target_asset_id UUID,  -- Will be renamed to target_entity_id by migration
  suggestion_text TEXT NOT NULL,
  suggestion_type TEXT NOT NULL,
  issued_by TEXT NOT NULL DEFAULT 'reconindex',
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  implementation_status TEXT NOT NULL DEFAULT 'pending',
  followup_status TEXT NOT NULL DEFAULT 'unreviewed',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Assets table (will be dropped by migration)
CREATE TABLE IF NOT EXISTS assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID REFERENCES sources(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  asset_type TEXT NOT NULL,
  description TEXT,
  ecosystem TEXT[],
  stage TEXT,
  meta JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert test data
INSERT INTO assets (id, name, asset_type, description) VALUES
  (gen_random_uuid(), 'Test Bot', 'agent', 'A test trading bot'),
  (gen_random_uuid(), 'Test Project', 'project', 'A test project');
```

---

## Step 5: Apply Phase 1 Schema Files

Navigate to the schema directory and run files in order:

```bash
cd /home/agent/workspace/schema

# Set connection string (replace with your staging credentials)
export STAGING_DB="postgresql://postgres:<password>@db.<staging-ref>.supabase.co:5432/postgres"

# Phase 1: Core tables
psql "$STAGING_DB" -f core/003_entities.sql
psql "$STAGING_DB" -f core/004_entity_profiles.sql
psql "$STAGING_DB" -f core/005_entity_relationships.sql

# Phase 2: Taxonomy tables
psql "$STAGING_DB" -f taxonomy/006_classification_types.sql
psql "$STAGING_DB" -f taxonomy/007_categories.sql
psql "$STAGING_DB" -f taxonomy/008_tags.sql
psql "$STAGING_DB" -f taxonomy/020_entity_classifications.sql

# Phase 3: Content tables
psql "$STAGING_DB" -f content/010_submissions.sql
psql "$STAGING_DB" -f content/013_content_items.sql
psql "$STAGING_DB" -f content/014_ecosystem_updates.sql

# Phase 4: Migration (CRITICAL — runs last)
psql "$STAGING_DB" -f migrations/000_drop_assets_and_migrate.sql
```

---

## Step 6: Verify Migration

Run these checks in Supabase SQL Editor or via psql:

```sql
-- 1. Verify entities table has data
SELECT COUNT(*) AS entity_count FROM entities;
-- Expected: >= 2 (from test assets)

-- 2. Verify assets table is gone
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_name = 'assets'
) AS assets_exists;
-- Expected: FALSE

-- 3. Verify submissions.entity_id exists
SELECT column_name FROM information_schema.columns
WHERE table_name = 'submissions' AND column_name = 'entity_id';
-- Expected: One row with column_name = 'entity_id'

-- 4. Verify suggestion_outcomes.target_entity_id exists
SELECT column_name FROM information_schema.columns
WHERE table_name = 'suggestion_outcomes' AND column_name = 'target_entity_id';
-- Expected: One row with column_name = 'target_entity_id'

-- 5. Verify taxonomy tables are seeded
SELECT COUNT(*) AS category_count FROM categories;
-- Expected: 9

SELECT COUNT(*) AS classification_type_count FROM classification_types;
-- Expected: 5

-- 6. Verify content tables exist
SELECT COUNT(*) AS content_item_count FROM content_items;
-- Expected: 0 (empty, ready for data)

SELECT COUNT(*) AS ecosystem_update_count FROM ecosystem_updates;
-- Expected: 0 (empty, ready for data)

-- 7. List all tables to confirm structure
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Expected tables after migration:
- `sources`, `permissions`, `submissions`, `knowledge_units` (existing)
- `entities`, `entity_profiles`, `entity_relationships` (new core)
- `classification_types`, `categories`, `tags`, `entity_classifications`, `entity_tags`, `knowledge_unit_tags` (new taxonomy)
- `content_items`, `ecosystem_updates` (new content)
- `suggestion_outcomes`, `knowledge_gaps`, `agent_trust_scores`, `source_maturity` (from Phase 2A)
- **NOT:** `assets` (dropped)

---

## Step 7: Test API Endpoints (Optional)

If you want to test the Cloudflare Worker against staging:

1. Update Worker environment variables to point to staging Supabase:
   ```toml
   # wrangler.toml
   [vars]
   SUPABASE_URL = "https://<staging-ref>.supabase.co"
   SUPABASE_KEY = "<staging-anon-key>"
   ```

2. Deploy to staging Worker:
   ```bash
   cd reconindex-api
   wrangler deploy --env staging
   ```

3. Test endpoints:
   ```bash
   # Create an entity
   curl -X POST https://staging-api.reconindex.com/entities \
     -H "Authorization: Bearer <test-token>" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "Test NFT Collection",
       "entity_type": "nft_collection",
       "description": "A test NFT collection"
     }'

   # List entities
   curl https://staging-api.reconindex.com/entities
   ```

---

## Troubleshooting

### Error: "relation 'entities' already exists"
**Cause:** You ran the SQL file twice.  
**Fix:** Safe to ignore — all files use `CREATE TABLE IF NOT EXISTS`.

### Error: "foreign key constraint violated"
**Cause:** Trying to reference a table that doesn't exist yet.  
**Fix:** Ensure you're running files in the correct order from `DEPLOYMENT_ORDER.md`.

### Error: "column 'asset_id' does not exist"
**Cause:** Migration already ran, or you're using a fresh database without the `assets` table.  
**Fix:** Safe to ignore — migration script checks for this and skips if `asset_id` doesn't exist.

### Error: "permission denied for schema public"
**Cause:** Wrong database user.  
**Fix:** Ensure you're connecting as `postgres` user, not the anon role.

---

## Next Steps After Successful Staging Test

1. ✅ All verification queries pass
2. ✅ No errors in migration output
3. ✅ Test creating entities, profiles, relationships via SQL
4. ✅ Test inserting content items and ecosystem updates
5. **Deploy to production Supabase** — same steps, but use production credentials
6. **Update Cloudflare Worker** — add new API endpoints
7. **Update frontend** — make reconindex.com dynamic

---

*Staging setup guide lives at: `/home/agent/workspace/schema/STAGING_SETUP.md`*
