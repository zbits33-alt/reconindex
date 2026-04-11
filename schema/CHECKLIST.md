# Schema Evolution — Quick Checklist

> Use this to track progress through Phase 1 deployment.

---

## Review Complete ✅

- [x] Migration SQL drafted (`000_drop_assets_and_migrate.sql`)
- [x] Core tables drafted (3 files)
- [x] Taxonomy tables drafted (4 files)
- [x] Content tables drafted (3 files)
- [x] Deployment order documented
- [x] Rollback plan included
- [x] Staging setup guide written
- [x] SQL syntax reviewed (no errors found)
- [x] Fixed `RETURN` statement issue in migration script
- [x] Verified no conflicts with existing Phase 2A tables

---

## Staging Test (In Progress)

- [ ] Create staging Supabase project
- [ ] Get connection details (host, password, project ref)
- [ ] Install psql client (if needed)
- [ ] Apply base schema (sources, permissions, submissions, assets, etc.)
- [ ] Run Phase 1 SQL files in order
- [ ] Run migration script
- [ ] Verify all checks pass
- [ ] Test creating entities, profiles, content items

---

## Production Deployment (Pending)

- [ ] Backup production database (pg_dump)
- [ ] Notify any active users of maintenance window
- [ ] Apply Phase 1 SQL files to production
- [ ] Run migration script on production
- [ ] Verify production data migrated correctly
- [ ] Update Cloudflare Worker environment variables (if needed)
- [ ] Deploy updated Worker API
- [ ] Update frontend to use new APIs
- [ ] Monitor logs for errors (24–48 hours)

---

## Post-Deployment Tasks

- [ ] Seed initial entity profiles (Predator, QuantX, DKTrenchBot)
- [ ] Create sample content items (guides, warnings, pattern reports)
- [ ] Test submission flow end-to-end
- [ ] Update documentation (RECON_BLUEPRINT.md, BOOTSTRAP.md)
- [ ] Remove old `assets` references from codebase
- [ ] Archive this checklist

---

## Files Created

| File | Purpose | Status |
|------|---------|--------|
| `schema/core/003_entities.sql` | Master entity table | ✅ Drafted |
| `schema/core/004_entity_profiles.sql` | Public display data | ✅ Drafted |
| `schema/core/005_entity_relationships.sql` | Ecosystem graph | ✅ Drafted |
| `schema/taxonomy/006_classification_types.sql` | Classification dimensions | ✅ Drafted + Seeded |
| `schema/taxonomy/007_categories.sql` | Submission categories | ✅ Drafted + Seeded |
| `schema/taxonomy/008_tags.sql` | Tag taxonomy system | ✅ Drafted |
| `schema/taxonomy/020_entity_classifications.sql` | Entity ↔ classification junction | ✅ Drafted |
| `schema/content/010_submissions.sql` | Documents entity_id change | ✅ Drafted |
| `schema/content/013_content_items.sql` | Browseable content layer | ✅ Drafted |
| `schema/content/014_ecosystem_updates.sql` | Living XRPL feed | ✅ Drafted |
| `schema/migrations/000_drop_assets_and_migrate.sql` | Critical migration script | ✅ Drafted + Fixed |
| `schema/DEPLOYMENT_ORDER.md` | Execution order + rollback | ✅ Written |
| `schema/README.md` | Summary + next steps | ✅ Written |
| `schema/STAGING_SETUP.md` | Staging test guide | ✅ Written |
| `SCHEMA_EVOLUTION_PLAN.md` | Full design doc (workspace root) | ✅ Written |

**Total:** 15 files, ~800 lines of SQL + docs

---

*Checklist lives at: `/home/agent/workspace/schema/CHECKLIST.md`*
