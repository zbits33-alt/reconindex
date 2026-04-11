# Schema Evolution Plan — Assets → Entities

> Created: 2026-04-11  
> Status: Design complete, implementation pending  
> Source: Operator analysis + Recon assessment

---

## Overview

The current `assets` table is too narrow for Society Libraries' ambitions. It was designed for agent submissions (bots, workflows, tools) but needs to model the entire XRPL ecosystem: tokens, NFT collections, DeFi apps, media brands, communities, events.

**Solution:** Replace `assets` with `entities` — a canonical master table for anything with an identity in the ecosystem.

---

## Why This Change Is Necessary

### Current Problem

The `assets` table has only 8 `asset_type` values:
- `agent`, `project`, `workflow`, `guide`, `dataset`, `incident`, `tool`, `strategy`

This cannot cleanly represent:
- Meme coins, NFT collections, DeFi protocols
- Media brands, community groups, events
- Infrastructure providers, wallets, analytics tools
- Documentation hubs, partner programs

Jamming all of these into 8 types breaks down fast and makes the browsing experience confusing.

### The Fix

`entities` table with 19 `entity_type` values:
- `project`, `platform`, `protocol`, `token`, `meme_coin`
- `nft_collection`, `nft_project`, `defi_app`, `marketplace`
- `infrastructure`, `wallet`, `tool`, `service`
- `media`, `community`, `developer_tool`, `analytics_tool`
- `documentation`, `event`, `partner`

This covers the full spectrum without being so granular they're unmaintainable.

---

## Phase 1 Scope

### Tables to Create

| Table | Purpose |
|-------|---------|
| `entities` | Canonical master record for any ecosystem object |
| `entity_profiles` | Public-facing details for browsing (slug, descriptions, website, logo, etc.) |
| `entity_classifications` | Junction table linking entities to classification dimensions |
| `classification_types` | Controlled vocabulary for classification dimensions (chain_scope, vertical, audience, etc.) |
| `entity_relationships` | Ecosystem graph (partnered_with, built_by, integrates_with, etc.) |
| `content_items` | Browseable content layer (guides, tutorials, project briefs, warnings, pattern reports) |
| `ecosystem_updates` | Living feed of XRPL activity (launches, updates, partnerships, warnings) |
| `categories` | Controlled vocabulary for submission/knowledge_unit categories |
| `tags` | Proper tag taxonomy system (replaces TEXT[] arrays) |
| `entity_tags` | Junction: entities ↔ tags |
| `knowledge_unit_tags` | Junction: knowledge_units ↔ tags |

### Tables to Update

| Table | Change |
|-------|--------|
| `submissions` | `asset_id` → `entity_id` (FK update) |
| `suggestion_outcomes` | `target_asset_id` → `target_entity_id` (FK update) |

### Tables to Drop

| Table | Reason |
|-------|--------|
| `assets` | Replaced by `entities` |

### Tables Already Existing (No Change)

- `sources`, `permissions`, `knowledge_units`, `library_candidates`, `patterns`, `safety_flags`, `suggestions`, `knowledge_gaps` — all stay as-is.

---

## Phase 2 Scope (Deferred)

| Table | Purpose |
|-------|---------|
| `tracked_accounts` | X/Twitter social monitoring (handle, platform, trust score, linked entity) |
| `nft_collections` | NFT-specific metadata (floor price, supply, traits) |
| `nft_traits` | Trait rarity tracking |
| `nft_rewards` | Reward mechanics for NFT holders |
| `token_profiles` | Token-specific metadata (supply, circulating, contract address) |
| `defi_profiles` | DeFi-specific metadata (TVL, APY, supported chains) |

**Rationale for deferral:** No point building specialized tables until you have real data flowing through Phase 1. Get the core browsing experience working first.

---

## Migration Strategy

### Step 1: Create `entities` table

```sql
CREATE TABLE entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID REFERENCES sources(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  entity_type TEXT NOT NULL CHECK (entity_type IN (
    'project', 'platform', 'protocol', 'token', 'meme_coin',
    'nft_collection', 'nft_project', 'defi_app', 'marketplace',
    'infrastructure', 'wallet', 'tool', 'service',
    'media', 'community', 'developer_tool', 'analytics_tool',
    'documentation', 'event', 'partner'
  )),
  description TEXT,
  ecosystem TEXT[],
  stage TEXT CHECK (stage IN ('concept', 'prototype', 'testing', 'live', 'deprecated')),
  meta JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Step 2: Migrate existing `assets` → `entities`

```sql
INSERT INTO entities (id, source_id, name, entity_type, description, ecosystem, stage, meta, created_at, updated_at)
SELECT id, source_id, name,
  CASE asset_type
    WHEN 'agent' THEN 'tool'
    WHEN 'project' THEN 'project'
    WHEN 'workflow' THEN 'tool'
    WHEN 'guide' THEN 'documentation'
    WHEN 'dataset' THEN 'tool'
    WHEN 'incident' THEN 'event'
    WHEN 'tool' THEN 'tool'
    WHEN 'strategy' THEN 'documentation'
  END,
  description, ecosystem, stage, meta, created_at, updated_at
FROM assets;
```

### Step 3: Update FK references

```sql
-- submissions.asset_id → entity_id
ALTER TABLE submissions DROP CONSTRAINT IF EXISTS submissions_asset_id_fkey;
ALTER TABLE submissions RENAME COLUMN asset_id TO entity_id;
ALTER TABLE submissions ADD CONSTRAINT submissions_entity_id_fkey
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE SET NULL;

-- suggestion_outcomes.target_asset_id → target_entity_id
ALTER TABLE suggestion_outcomes DROP CONSTRAINT IF EXISTS suggestion_outcomes_target_asset_id_fkey;
ALTER TABLE suggestion_outcomes RENAME COLUMN target_asset_id TO target_entity_id;
ALTER TABLE suggestion_outcomes ADD CONSTRAINT suggestion_outcomes_target_entity_id_fkey
  FOREIGN KEY (target_entity_id) REFERENCES entities(id) ON DELETE SET NULL;
```

### Step 4: Drop `assets` table

```sql
DROP TABLE IF EXISTS assets;
```

---

## Key Design Decisions

### 1. `entity_classifications` as Junction Table (Not Flat Columns)

**Wrong approach:** Flat columns like `chain_scope`, `vertical`, `audience` in a single table. Becomes rigid fast.

**Right approach:**
```sql
CREATE TABLE classification_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,  -- e.g. 'chain_scope', 'vertical', 'audience'
  description TEXT,
  allowed_values TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE entity_classifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  classification_type_id UUID REFERENCES classification_types(id),
  value TEXT NOT NULL,
  assigned_by TEXT DEFAULT 'reconindex',
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  confidence NUMERIC DEFAULT 0.5,
  UNIQUE(entity_id, classification_type_id)
);
```

This lets you add new classification dimensions without schema changes.

### 2. `entity_relationships` with Type Enum

```sql
CREATE TABLE entity_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  to_entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL CHECK (relationship_type IN (
    'partnered_with', 'built_by', 'integrates_with', 'powers',
    'part_of', 'related_to', 'supports', 'competes_with',
    'forked_from', 'acquired_by', 'inspired_by'
  )),
  bidirectional BOOLEAN DEFAULT FALSE,
  confidence NUMERIC DEFAULT 0.5,
  source TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(from_entity_id, to_entity_id, relationship_type)
);
```

### 3. `content_items` with Status Workflow

```sql
CREATE TABLE content_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE SET NULL,
  content_type TEXT NOT NULL CHECK (content_type IN (
    'guide', 'tutorial', 'explainer', 'update', 'project_brief',
    'ecosystem_report', 'warning', 'event_post', 'profile', 'pattern_report'
  )),
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  body TEXT,
  summary TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft', 'in_review', 'approved', 'published', 'archived'
  )),
  author TEXT,
  published_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  view_count INT DEFAULT 0,
  meta JSONB DEFAULT '{}'
);
```

### 4. `ecosystem_updates` Linked to Sources

```sql
CREATE TABLE ecosystem_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE SET NULL,
  source_account TEXT,
  headline TEXT NOT NULL,
  summary TEXT,
  source_url TEXT,
  update_type TEXT CHECK (update_type IN (
    'launch', 'update', 'partnership', 'warning', 'milestone',
    'community', 'technical', 'market', 'governance', 'other'
  )),
  importance_score NUMERIC DEFAULT 0.5,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  approved BOOLEAN DEFAULT FALSE,
  approved_by TEXT,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 5. `tags` as Proper Taxonomy

```sql
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  category TEXT,
  usage_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE entity_tags (
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  assigned_by TEXT DEFAULT 'reconindex',
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (entity_id, tag_id)
);

CREATE TABLE knowledge_unit_tags (
  knowledge_unit_id UUID REFERENCES knowledge_units(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (knowledge_unit_id, tag_id)
);
```

### 6. `categories` as Controlled Vocabulary

```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES categories(id),
  library_section TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

Seed with existing values: `identity`, `build`, `operational`, `performance`, `failure`, `knowledge`, `safety`, `friction`, `audit_request`.

---

## Revised File Split

```
/core
  001_sources.sql
  002_permissions.sql
  003_entities.sql              ← replaces assets
  004_entity_profiles.sql
  005_entity_relationships.sql
  006_classification_types.sql
  007_categories.sql
  008_tags.sql

/content
  010_submissions.sql           ← update FK: entity_id instead of asset_id
  011_knowledge_units.sql
  012_library_candidates.sql
  013_content_items.sql
  014_ecosystem_updates.sql

/taxonomy
  020_entity_classifications.sql
  021_entity_tags.sql
  022_knowledge_unit_tags.sql

/tracking
  030_patterns.sql
  031_safety_flags.sql
  032_suggestions.sql
  033_knowledge_gaps.sql
  034_tracked_accounts.sql      ← Phase 2
  035_agent_trust_scores.sql    ← from Phase 2A migration
  036_source_maturity.sql       ← from Phase 2A migration
  037_suggestion_outcomes.sql   ← from Phase 2A migration

/specialized
  040_nft_collections.sql       ← Phase 2
  041_nft_traits.sql
  042_nft_rewards.sql
  043_token_profiles.sql
  044_defi_profiles.sql

/migrations
  000_drop_assets_and_migrate.sql
```

---

## Effort Estimate

### Breakdown by Task

| Task | Effort | Notes |
|------|--------|-------|
| Write migration SQL | 2–3 hours | Drop `assets`, create `entities`, migrate data, update FKs, add indexes |
| Create 8+ new tables | 3–4 hours | Schema design done. Writing SQL, constraints, indexes, comments |
| Update existing tables | 1 hour | ALTER TABLE + FK updates. Trivial if no live data |
| Update Cloudflare Worker API | 4–6 hours | New endpoints, validation logic, entity type handling |
| Update Recon intelligence filter | 2–3 hours | Auto-classification for new entity types |
| Update landing page + dashboard | 2–3 hours | Dynamic browsing from `/entities` and `/content-items` APIs |
| Seed initial data | 1–2 hours | Populate `categories`, migrate `assets`, create sample profiles |
| Testing + deployment | 2–3 hours | Staging test, deploy, monitor |

### Total: ~17–25 hours of focused work

**Timeline:** 2–3 full working days if doing it yourself with AI assistance. 1.5–2 days if delegated to a developer who knows Supabase + Cloudflare Workers.

---

## Cost Impact

**Zero additional cost** for schema changes. Supabase free tier handles 500MB database + 1GB bandwidth. Cloudflare Workers free tier handles 100K requests/day.

Only cost increase would be from additional cron jobs or API-triggered agent sessions — not from the schema itself.

---

## Recommendation

**Execute Phase 1 now.**

### Why Now

1. **No live production data** — Recon Index is still bootstrapping. Breaking changes are cheap now, expensive later.
2. **Current schema blocks vision** — Can't build proper Society Libraries browsing experience with 8 asset types.
3. **Phase 1 is self-contained** — Don't need Phase 2 (tracked_accounts, NFT tables) to launch.
4. **2–3 days is worth it** — Once done, never revisit core schema. Every future addition fits without breaking changes.

### Execution Order

1. Write migration SQL
2. Create staging Supabase project (free, 2 minutes)
3. Test migration on staging
4. Update Worker API (add endpoints, test with `wrangler dev`)
5. Deploy to production (migration first, then Worker)
6. Update frontend (make reconindex.com dynamic)
7. Verify (check logs, test submission flow)

---

## Schema Test

The proposed schema passes this test:

> *"If someone visits Society Libraries and clicks an item, they should quickly understand:*
> - *what it is*
> - *what type of thing it is*
> - *whether it's XRPL-native or cross-chain*
> - *what category it belongs to*
> - *who it's for*
> - *the latest updates*
> - *related guides or warnings"*

---

## Next Steps

When ready to implement:
1. Draft the full migration SQL (`/migrations/000_drop_assets_and_migrate.sql`)
2. Set up staging Supabase project
3. Test migration end-to-end
4. Update Cloudflare Worker handlers
5. Deploy

---

*This document lives at: `/home/agent/workspace/SCHEMA_EVOLUTION_PLAN.md`*
