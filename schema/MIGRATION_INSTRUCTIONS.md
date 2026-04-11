# Migration Instructions — Add walkie_id Column

## What Needs to Happen

The `sources` table in Supabase needs a new column: `walkie_id TEXT`

This column stores each agent's Walkie identity so Recon can respond via P2P messaging.

## How to Run It

### Option 1: Supabase Dashboard (Recommended)

1. Go to https://supabase.com/dashboard/project/nygdcvjmjzvyxljexjjo
2. Click **SQL Editor** in the left sidebar
3. Click **New query**
4. Paste this SQL:

```sql
ALTER TABLE sources ADD COLUMN IF NOT EXISTS walkie_id TEXT;

COMMENT ON COLUMN sources.walkie_id IS 'Agent Walkie identity for P2P messaging responses (e.g., "MyTradingBot")';
```

5. Click **Run** (or Ctrl+Enter)
6. You should see: `Success. No rows returned`

### Option 2: Supabase CLI (If Installed)

```bash
supabase db execute -f schema/migrations/006_add_walkie_id.sql --project-ref nygdcvjmjzvyxljexjjo
```

## After Running

Once the migration is complete:

1. Uncomment the `walkie_id` lines in `reconindex-api/worker.js`:
   - Line ~705 in `handlePublicConnect`
   - Line ~611 in `handleIntakeRegister`

2. Redeploy the Worker:
   ```bash
   cd reconindex-api
   CLOUDFLARE_API_TOKEN=cfut_GBJ0dhYwCXH1PHYW6YOJPzFQRFQmf4xqGr6EWTSWd44f6f25 npx wrangler deploy
   ```

3. Test registration with Walkie ID:
   ```bash
   curl -X POST https://api.reconindex.com/intake/connect \
     -H "Content-Type: application/json" \
     -d '{"name":"TestWalkieBot","type":"agent","operator":"Test","walkie_id":"TestWalkieBot"}'
   ```

## Current Status

- ✅ Migration file created: `schema/migrations/006_add_walkie_id.sql`
- ✅ Worker code ready (walkie_id lines commented out)
- ❌ Column not yet added to Supabase (requires manual SQL execution)
- ⚠️ Registration works without walkie_id (field is optional)

---

*Created: 2026-04-11 | Priority: Medium (blocks Walkie ID tracking)*
