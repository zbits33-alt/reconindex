# Phase 1 Minimums — Recon Index MVP
> Version 1.0 | Created: 2026-04-09
> Optimize for: fast launch, low cost, durability, safety, strict permissions, clean migration path.
> Rule: if it can wait, it waits.

---

## The Core Intelligence Loop (never compromise this)

```
Source submits → Worker validates + stores → Recon classifies → Knowledge unit created → Pattern detected → Library candidate flagged
```

Everything in Phase 1 exists to keep this loop alive. Nothing else is required yet.

---

## 1. Minimum Viable Supabase Schema

Five tables. No more.

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Who is submitting
CREATE TABLE sources (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         TEXT NOT NULL,
  type         TEXT NOT NULL,                    -- agent | tool | human | project
  owner        TEXT,
  api_token    TEXT UNIQUE NOT NULL,             -- store hashed (bcrypt)
  default_tier SMALLINT NOT NULL DEFAULT 2,      -- 1=public 2=shared 3=restricted 4=secret
  permissions  JSONB NOT NULL DEFAULT '{}',      -- allow_logs, allow_code, never_store[], etc.
  cadence      TEXT NOT NULL DEFAULT 'standard', -- high_frequency | standard | low_frequency
  last_seen    TIMESTAMPTZ,
  next_due     TIMESTAMPTZ,
  active       BOOLEAN DEFAULT TRUE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- What they submit
CREATE TABLE submissions (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id    UUID REFERENCES sources(id) ON DELETE SET NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  tier         SMALLINT NOT NULL DEFAULT 2,
  category     TEXT NOT NULL,                    -- identity | operational | failure | knowledge | safety | friction
  summary      TEXT NOT NULL,                    -- max 500 chars
  content      TEXT NOT NULL,                    -- max 50KB
  r2_keys      TEXT[],                           -- blobs stored in R2
  status       TEXT DEFAULT 'received',          -- received | classified | flagged | archived
  score        SMALLINT,                         -- 1–10, set at classification
  request_id   TEXT                              -- echoed from update request, nullable
);

-- Distilled insights
CREATE TABLE knowledge_units (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id UUID REFERENCES submissions(id) ON DELETE SET NULL,
  source_id     UUID REFERENCES sources(id) ON DELETE SET NULL,
  tier          SMALLINT NOT NULL,
  category      TEXT NOT NULL,
  title         TEXT NOT NULL,
  summary       TEXT NOT NULL,
  key_insight   TEXT NOT NULL,
  tags          TEXT[],
  score         SMALLINT,                        -- 1–10
  library_flag  BOOLEAN DEFAULT FALSE,           -- ready for library promotion?
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Recurring patterns across sources
CREATE TABLE patterns (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pattern_type   TEXT NOT NULL,                  -- failure | fix | friction | success | safety | workflow
  title          TEXT NOT NULL,
  description    TEXT,
  count          INT DEFAULT 1,
  first_seen     TIMESTAMPTZ DEFAULT NOW(),
  last_seen      TIMESTAMPTZ DEFAULT NOW(),
  tags           TEXT[]
);

-- Safety and sensitive item flags
CREATE TABLE safety_flags (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id UUID REFERENCES submissions(id) ON DELETE CASCADE,
  source_id     UUID REFERENCES sources(id) ON DELETE SET NULL,
  flag_type     TEXT NOT NULL,                   -- secret_exposure | unsafe_practice | policy_violation | other
  severity      TEXT DEFAULT 'medium',           -- low | medium | high | critical
  description   TEXT,
  resolved      BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes (minimum set for Phase 1 query patterns)
CREATE INDEX idx_submissions_source   ON submissions(source_id);
CREATE INDEX idx_submissions_status   ON submissions(status);
CREATE INDEX idx_knowledge_units_flag ON knowledge_units(library_flag) WHERE library_flag = TRUE;
CREATE INDEX idx_safety_flags_open    ON safety_flags(severity) WHERE resolved = FALSE;
```

**What was cut vs RECON_BLUEPRINT.md:**
| Removed | Reason | Add in Phase |
|---------|--------|-------------|
| `assets` table | Sources + submissions cover it. Assets = premature normalization. | Phase 2 |
| `permissions` table | Folded into `sources.permissions JSONB`. Simpler, still queryable. | Phase 2 if needed |
| `library_candidates` table | `knowledge_units.library_flag = true` is enough for now. Full review table overkill. | Phase 2 |
| `pgvector` extension | No embeddings in Phase 1. Expensive and unused. | Phase 2 |
| `audit_queue` | Not needed until volume justifies it. | Phase 2 |

**Migration safety:** The full RECON_BLUEPRINT.md schema is a superset of this one. Every column here maps cleanly forward. No rework needed when expanding.

---

## 2. Minimum Viable Cloudflare Worker Endpoints

Four routes. That's it.

```
POST  /submit           → intake a submission from a source
POST  /register         → register a new source (admin only)
GET   /status/:id       → check submission status
GET   /health           → liveness check
```

### POST /submit

**Auth:** `Authorization: Bearer {agent_token}`

**Request:**
```jsonc
{
  "category": "operational",      // identity | operational | failure | knowledge | safety | friction
  "summary": "string",            // required, max 500 chars
  "content": "string",            // required, max 50KB
  "tier": 2,                      // optional, cannot exceed source default
  "tags": [],                     // optional
  "request_id": "string",         // optional, echoed from update request
  "blobs": []                     // optional, max 3 × 5MB, base64
}
```

**Worker logic (in order):**
1. Authenticate bearer token → resolve source
2. Validate required fields + size limits
3. Tier check — cannot exceed `source.default_tier`
4. Secret scan — regex for keys, seeds, tokens in `content`
   - Match found → strip content, write `safety_flag`, return 200 with `flagged: true`
5. Write blobs to R2 if present
6. Insert `submissions` row
7. Update `sources.last_seen`
8. Return `{ submission_id, status: "received", flagged: false }`

**Response:**
```jsonc
{
  "submission_id": "uuid",
  "status": "received",
  "flagged": false
}
```

---

### POST /register

**Auth:** `Authorization: Bearer {admin_token}` (env var, never in code)

**Request:**
```jsonc
{
  "name": "string",
  "type": "agent | tool | human | project",
  "owner": "string",
  "cadence": "high_frequency | standard | low_frequency",
  "permissions": {
    "allow_logs": false,
    "allow_code": false,
    "allow_perf_data": false,
    "allow_prompts": false,
    "allow_configs": false,
    "allow_library_promotion": false,
    "never_store": []
  }
}
```

**Returns:** `{ source_id, api_token }` — token shown once, bcrypt-hashed before storage.

---

### GET /status/:submission_id

**Auth:** Same bearer token as submitting source (cannot query other sources).

**Returns:**
```jsonc
{
  "submission_id": "uuid",
  "status": "received | classified | flagged | archived",
  "score": 7,
  "flagged": false
}
```

---

### GET /health

No auth. Returns `{ status: "ok", ts: "ISO-8601" }`. Used for uptime monitoring.

---

**What was cut:**
| Removed | Reason | Add in Phase |
|---------|--------|-------------|
| `POST /update-request` (outbound) | Phase 1 update requests sent manually by Recon agent. Automated dispatch is Phase 2. | Phase 2 |
| `GET /patterns` | Dashboard reads Supabase directly. No API proxy needed yet. | Phase 2 |
| `GET /library` | Same — direct Supabase read. | Phase 2 |
| Webhook callbacks | Overkill until multiple sources are active. | Phase 2 |
| Rate limiting per source | Supabase row-level limits cover it for now. | Phase 2 |

---

## 3. Minimum Viable Dashboard Modules

Three views. Static HTML + Supabase JS client. No framework needed.

### View 1 — Submissions Feed
**URL:** `app.reconindex.com`

| Element | Detail |
|---------|--------|
| List of recent submissions | source name, category, summary, score, status, timestamp |
| Filter by: status, category, tier | dropdowns, client-side |
| Click row → expand full content | inline expand, no new page |
| Flag indicator | red dot if `safety_flag` exists |

**Supabase query:**
```js
supabase.from('submissions')
  .select('*, sources(name)')
  .order('submitted_at', { ascending: false })
  .limit(50)
```

---

### View 2 — Knowledge Units + Library Flags
**URL:** `app.reconindex.com/library`

| Element | Detail |
|---------|--------|
| List of knowledge units with `library_flag = true` | title, key_insight, score, tags, source |
| Approve button → sets `library_flag = true` (already set), adds review note | simple text field |
| Reject button → sets `library_flag = false` | with note |
| All units view | toggle to see non-flagged units too |

**This is the promotion review queue.** Operator approves what enters Society Libraries.

---

### View 3 — Safety Flags
**URL:** `app.reconindex.com/safety`

| Element | Detail |
|---------|--------|
| Open flags only (resolved = false) | severity badge, type, description, source, timestamp |
| Resolve button | marks `resolved = true` |
| Severity filter | critical first by default |

**Purpose:** nothing sensitive slips through unreviewed.

---

**What was cut:**
| Removed | Reason | Add in Phase |
|---------|--------|-------------|
| Pattern visualization | Useful but not blocking the loop. | Phase 2 |
| Source management UI | Register via API for now. | Phase 2 |
| Analytics/charts | No volume to chart yet. | Phase 2 |
| Library publication UI | Manual export to start. | Phase 2 |
| Auth layer on dashboard | Basic HTTP auth on Cloudflare Pages is enough for now. | Phase 2 |
| Mobile-optimized views | Desktop-first is fine internally. | Phase 2 |

---

## 4. Explicit Phase 2 Deferrals

Do not touch these until Phase 1 is live and stable.

### Schema Deferrals
- `assets` table — sources + submissions is sufficient to start
- `library_candidates` table — `knowledge_units.library_flag` is the queue for now
- `pgvector` / embeddings — no semantic search until there's volume worth searching
- `permissions` table — JSONB column in `sources` handles Phase 1 needs
- `audit_queue` table — manual review covers Phase 1 throughput

### API Deferrals
- Outbound update request dispatch (automated)
- Webhook callbacks per source
- Per-source rate limiting
- Query API for agents (`GET /query?topic=...`)
- Public read API for Society Libraries

### Dashboard Deferrals
- Pattern browser / visualization
- Source management UI
- Analytics and charts
- Library publication workflow
- Authentication beyond HTTP basic auth
- Mobile layout

### Infrastructure Deferrals
- `recon-library` R2 bucket — one bucket is enough now
- `docs.reconindex.com` — no public docs yet
- `admin.reconindex.com` — dashboard covers admin needs
- Custom email notifications
- Slack/Discord webhooks for flag alerts
- CDN caching strategy

### Behavior Deferrals
- Automated update request dispatch via cron — Recon sends manually for now
- Automated pattern detection pipeline — manual classification first
- ChipGPT integration — no query layer until library has content
- Trust scoring per source — too early without data

---

## Phase 1 Launch Criteria

The system is live when:

```
[ ] POST /submit accepts a real submission from a real source
[ ] Submission is stored in Supabase
[ ] Blob (if attached) is stored in R2
[ ] Secret scan runs and flags correctly
[ ] knowledge_unit is created from the submission
[ ] library_flag is set correctly on high-score units
[ ] Submissions Feed shows the entry in the dashboard
[ ] Safety Flags view shows any flagged items
[ ] Predator (SRC-002) has submitted at least one update
[ ] Recon (SRC-001) has logged at least one self-submission
```

That's the minimum. Everything else is Phase 2.

---

*Companion documents:*
- `RECON_BLUEPRINT.md` — full architecture reference (Phase 1 + future)
- `RECURRING_UPDATE_SCHEMA.md` — update request/response spec
- `RECONINDEX_SETUP.md` — infrastructure setup checklist
- `RECON_ACTIVE_COLLECTION.md` — operating model
