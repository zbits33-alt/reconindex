# Schema Evolution — Phase 1 Complete

> Status: SQL files drafted, ready for deployment  
> Created: 2026-04-11  
> Next: Test on staging Supabase project

---

## What's Been Done

### 1. Migration Script Drafted
- **File:** `migrations/000_drop_assets_and_migrate.sql` (186 lines)
- Handles `assets` → `entities` migration with type mapping
- Updates FK references in `submissions` and `suggestion_outcomes`
- Drops `assets` table after successful migration
- Includes verification checks and rollback plan

### 2. Core Tables Created (5 files)
| File | Table | Purpose |
|------|-------|---------|
| `core/003_entities.sql` | `entities` | Master table for all ecosystem objects (19 types) |
| `core/004_entity_profiles.sql` | `entity_profiles` | Public-facing display data (slug, descriptions, logo, etc.) |
| `core/005_entity_relationships.sql` | `entity_relationships` | Ecosystem graph (partnerships, integrations, dependencies) |

### 3. Taxonomy Tables Created (4 files)
| File | Table(s) | Purpose |
|------|----------|---------|
| `taxonomy/006_classification_types.sql` | `classification_types` | Controlled vocabulary for classification dimensions (seeded with 5 types) |
| `taxonomy/007_categories.sql` | `categories` | Controlled vocabulary for submission categories (seeded with 9 categories) |
| `taxonomy/008_tags.sql` | `tags`, `entity_tags`, `knowledge_unit_tags` | Proper tag taxonomy system (replaces TEXT[] arrays) |
| `taxonomy/020_entity_classifications.sql` | `entity_classifications` | Junction table: entities ↔ classification types |

### 4. Content Tables Created (3 files)
| File | Table | Purpose |
|------|-------|---------|
| `content/010_submissions.sql` | `submissions` (updated) | Documents `entity_id` change (migration handled by migration script) |
| `content/013_content_items.sql` | `content_items` | Browseable content layer (guides, tutorials, warnings, pattern reports) |
| `content/014_ecosystem_updates.sql` | `ecosystem_updates` | Living feed of XRPL activity (launches, updates, partnerships) |

### 5. Deployment Order Documented
- **File:** `DEPLOYMENT_ORDER.md` (196 lines)
- Step-by-step execution order for all SQL files
- Verification queries to confirm success
- Rollback plan if migration fails

---

## File Structure

```
schema/
├── README.md                          ← this file
├── DEPLOYMENT_ORDER.md                ← execution order + rollback plan
├── core/
│   ├── 003_entities.sql               ← master entity table
│   ├── 004_entity_profiles.sql        ← public display data
│   └── 005_entity_relationships.sql   ← ecosystem graph
├── taxonomy/
│   ├── 006_classification_types.sql   ← classification dimensions (seeded)
│   ├── 007_categories.sql             ← submission categories (seeded)
│   ├── 008_tags.sql                   ← tag taxonomy system
│   └── 020_entity_classifications.sql ← entity ↔ classification junction
├── content/
│   ├── 010_submissions.sql            ← documents entity_id change
│   ├── 013_content_items.sql          ← browseable content layer
│   └── 014_ecosystem_updates.sql      ← living XRPL activity feed
└── migrations/
    └── 000_drop_assets_and_migrate.sql ← critical migration script
```

**Total:** 12 SQL files + 2 documentation files = 745 lines of SQL

---

## What's NOT Included Yet

These are deferred to Phase 2 or require separate work:

| Item | Status | Notes |
|------|--------|-------|
| `tracked_accounts` | Phase 2 | X/Twitter social monitoring |
| `nft_collections`, `nft_traits`, `nft_rewards` | Phase 2 | NFT-specific metadata |
| `token_profiles` | Phase 2 | Token-specific metadata |
| `defi_profiles` | Phase 2 | DeFi-specific metadata |
| Cloudflare Worker API updates | Pending | Need new endpoints for `/entities`, `/content-items`, etc. |
| Frontend updates | Pending | Make reconindex.com dynamic |
| Recon intelligence filter updates | Pending | Handle new entity types in auto-classification |

---

## Next Steps

### Immediate (Before Deployment)

1. **Review SQL files** — Check for syntax errors, missing constraints, or logic issues
2. **Create staging Supabase project** — Free tier, test migration there first
3. **Test migration end-to-end** — Run all SQL files in order, verify no errors

### After Staging Test

4. **Deploy to production Supabase** — Execute SQL files in order from `DEPLOYMENT_ORDER.md`
5. **Update Cloudflare Worker** — Add new API endpoints, update validation logic
6. **Update frontend** — Make reconindex.com fetch from new APIs
7. **Verify** — Test submission flow, check logs, confirm everything works

---

## Key Design Decisions

### 1. Junction Tables for Classifications
Instead of flat columns (`chain_scope`, `vertical`, `audience`) in a single table, we use:
- `classification_types` — defines available dimensions
- `entity_classifications` — junction table linking entities to classifications

**Benefit:** Add new classification dimensions without schema changes.

### 2. Controlled Vocabularies
`categories` and `classification_types` are proper tables, not enums or CHECK constraints.

**Benefit:** Admins can add new categories/classifications via SQL INSERT, no migration needed.

### 3. Tag Taxonomy System
Replaced `TEXT[]` arrays with:
- `tags` — master tag list with usage_count
- `entity_tags` — junction: entities ↔ tags
- `knowledge_unit_tags` — junction: knowledge_units ↔ tags

**Benefit:** Efficient querying ("find all entities tagged 'amm'"), tag merging, popularity tracking.

### 4. Content Status Workflow
`content_items` has a status field: `draft` → `in_review` → `approved` → `published` → `archived`

**Benefit:** Content goes through review before appearing in Society Libraries.

### 5. Ecosystem Updates Approval
`ecosystem_updates` has an `approved` flag — updates detected automatically (from tracked accounts, RSS feeds) must be approved before appearing publicly.

**Benefit:** Prevents spam or low-quality updates from cluttering the feed.

---

## Estimated Effort Remaining

| Task | Effort |
|------|--------|
| Review + test SQL on staging | 1–2 hours |
| Deploy to production Supabase | 30 minutes |
| Update Cloudflare Worker API | 4–6 hours |
| Update Recon intelligence filter | 2–3 hours |
| Update frontend (dynamic browsing) | 2–3 hours |
| Seed initial data (entity profiles) | 1–2 hours |
| Testing + verification | 2–3 hours |
| **Total** | **~13–20 hours** |

**Timeline:** 2–3 working days if doing it yourself with AI assistance.

---

*This document lives at: `/home/agent/workspace/schema/README.md`*
