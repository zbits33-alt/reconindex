# Recon Phase 1 — System Blueprint
> Version 0.2 | Status: Architecture Refined — Implementation Planning
> Updated: 2026-04-08 — expanded scope, query layer added, feedback loop formalized

---

## A. Phase 1 System Blueprint

### Components & Responsibilities

```
┌─────────────────────────────────────────────────────────────────┐
│                        AGENTS / HUMANS                          │
│          (submit data, request audits, contribute knowledge)     │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTPS POST
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                  CLOUDFLARE WORKERS (Front Door)                 │
│  • Auth: bearer token per agent                                  │
│  • Schema validation (reject malformed or oversized payloads)    │
│  • Tier enforcement (strip secrets, flag violations)             │
│  • Route to Supabase (structured) or R2 (blobs)                  │
│  • Return submission ID and status                               │
└───────────────┬─────────────────────────────┬───────────────────┘
                │ structured records           │ raw blobs
                ▼                             ▼
┌───────────────────────────┐   ┌─────────────────────────────────┐
│   SUPABASE (Postgres)     │   │   CLOUDFLARE R2 (Blob Store)     │
│                           │   │                                  │
│  • sources                │   │  • logs (.txt, .jsonl)           │
│  • assets                 │   │  • screenshots (.png, .jpg)      │
│  • permissions            │   │  • JSON payloads                 │
│  • submissions            │   │  • documents (.md, .pdf)         │
│  • knowledge_units        │   │  • raw config dumps              │
│  • library_candidates     │   │                                  │
│  • audit_queue            │   │  Path format:                    │
│  • patterns               │   │  /{source_id}/{submission_id}/   │
│  • safety_flags           │   │                                  │
└───────────────────────────┘   └─────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     RECON INTELLIGENCE LOOP                      │
│  (runs as cron or triggered — classify, score, promote, flag)    │
│                                                                  │
│  Submission → classify tier → extract knowledge candidates       │
│  → detect patterns → flag safety issues → promote to library     │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       SOCIETY LIBRARIES                          │
│         (curated, approved, public-safe knowledge output)         │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Summary

```
Agent submits → Worker validates + routes → R2 stores blobs, 
Supabase stores structured records → Recon classifies and scores → 
Knowledge candidates extracted → Human or Recon review → 
Approved items promoted to Society Libraries
```

---

## B. Minimal Supabase Schema

> Core tables only. Extensions first.

```sql
-- Enable pgvector for optional embedding support later
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────
-- 1. SOURCES
-- Who or what is submitting data to Recon
-- ─────────────────────────────────────────────────────────────
CREATE TABLE sources (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,                  -- agent or human name
  type          TEXT NOT NULL CHECK (type IN (
                  'agent', 'bot', 'tool', 'workflow',
                  'human', 'data_source', 'documentation'
                )),
  owner         TEXT,                           -- operator handle or org
  ecosystem     TEXT[],                         -- e.g. ['xrpl', 'evm', 'flare']
  api_token     TEXT UNIQUE NOT NULL,           -- hashed bearer token
  active        BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  meta          JSONB DEFAULT '{}'              -- flexible extras
);

-- ─────────────────────────────────────────────────────────────
-- 2. PERMISSIONS
-- What each source allows Recon to store and use
-- ─────────────────────────────────────────────────────────────
CREATE TABLE permissions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id       UUID REFERENCES sources(id) ON DELETE CASCADE,
  default_tier    SMALLINT NOT NULL DEFAULT 2 CHECK (default_tier BETWEEN 1 AND 4),
  allow_logs      BOOLEAN DEFAULT FALSE,
  allow_screenshots BOOLEAN DEFAULT FALSE,
  allow_code      BOOLEAN DEFAULT FALSE,
  allow_prompts   BOOLEAN DEFAULT FALSE,
  allow_configs   BOOLEAN DEFAULT FALSE,
  allow_perf_data BOOLEAN DEFAULT FALSE,
  allow_anonymized_sharing BOOLEAN DEFAULT TRUE,
  allow_library_promotion  BOOLEAN DEFAULT FALSE,
  never_store     TEXT[],                       -- explicit exclusion list
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 3. ASSETS
-- The thing being described: bot, project, workflow, guide, etc.
-- ─────────────────────────────────────────────────────────────
CREATE TABLE assets (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id     UUID REFERENCES sources(id) ON DELETE SET NULL,
  name          TEXT NOT NULL,
  asset_type    TEXT NOT NULL CHECK (asset_type IN (
                  'agent', 'project', 'workflow', 'guide',
                  'dataset', 'incident', 'tool', 'strategy'
                )),
  description   TEXT,
  ecosystem     TEXT[],
  stage         TEXT CHECK (stage IN (
                  'concept', 'prototype', 'testing', 'live', 'deprecated'
                )),
  stack         TEXT[],                         -- frameworks, tools used
  hosting       TEXT,                           -- where it runs
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  meta          JSONB DEFAULT '{}'
);

-- ─────────────────────────────────────────────────────────────
-- 4. SUBMISSIONS
-- The actual payload from a source about an asset
-- ─────────────────────────────────────────────────────────────
CREATE TABLE submissions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id       UUID REFERENCES sources(id) ON DELETE SET NULL,
  asset_id        UUID REFERENCES assets(id) ON DELETE SET NULL,
  submitted_at    TIMESTAMPTZ DEFAULT NOW(),
  tier            SMALLINT NOT NULL DEFAULT 2 CHECK (tier BETWEEN 1 AND 4),
  category        TEXT NOT NULL CHECK (category IN (
                    'identity', 'build', 'operational', 'performance',
                    'failure', 'knowledge', 'safety', 'friction', 'audit_request'
                  )),
  summary         TEXT,                         -- human-readable summary
  content         TEXT,                         -- main text payload
  r2_keys         TEXT[],                       -- pointers to R2 blobs
  status          TEXT DEFAULT 'received' CHECK (status IN (
                    'received', 'processing', 'classified',
                    'flagged', 'archived', 'rejected'
                  )),
  usefulness_score SMALLINT,                    -- 1–10, set during classification
  meta            JSONB DEFAULT '{}'
);

-- ─────────────────────────────────────────────────────────────
-- 5. KNOWLEDGE UNITS
-- Distilled, reusable insights extracted from submissions
-- ─────────────────────────────────────────────────────────────
CREATE TABLE knowledge_units (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id   UUID REFERENCES submissions(id) ON DELETE SET NULL,
  source_id       UUID REFERENCES sources(id) ON DELETE SET NULL,
  tier            SMALLINT NOT NULL CHECK (tier BETWEEN 1 AND 4),
  category        TEXT NOT NULL,                -- mirrors submission categories
  title           TEXT NOT NULL,
  summary         TEXT NOT NULL,
  key_insight     TEXT NOT NULL,
  tags            TEXT[],
  usefulness_score SMALLINT CHECK (usefulness_score BETWEEN 1 AND 10),
  repeat_count    INT DEFAULT 1,                -- how often this pattern appears
  library_candidate BOOLEAN DEFAULT FALSE,
  embedding       VECTOR(1536),                 -- optional: add later for semantic search
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 6. LIBRARY CANDIDATES
-- Knowledge units reviewed and approved for Society Libraries
-- ─────────────────────────────────────────────────────────────
CREATE TABLE library_candidates (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  knowledge_unit_id UUID REFERENCES knowledge_units(id) ON DELETE CASCADE,
  draft_title     TEXT NOT NULL,
  draft_content   TEXT NOT NULL,
  category        TEXT,
  review_status   TEXT DEFAULT 'pending' CHECK (review_status IN (
                    'pending', 'approved', 'rejected', 'needs_revision'
                  )),
  reviewer_notes  TEXT,
  published_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 7. PATTERNS
-- Recurring issues, fixes, or behaviors detected across sources
-- ─────────────────────────────────────────────────────────────
CREATE TABLE patterns (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pattern_type    TEXT NOT NULL CHECK (pattern_type IN (
                    'failure', 'fix', 'friction', 'success',
                    'safety', 'architecture', 'workflow'
                  )),
  title           TEXT NOT NULL,
  description     TEXT,
  occurrence_count INT DEFAULT 1,
  first_seen      TIMESTAMPTZ DEFAULT NOW(),
  last_seen       TIMESTAMPTZ DEFAULT NOW(),
  linked_units    UUID[],                       -- knowledge_unit ids
  tags            TEXT[]
);

-- ─────────────────────────────────────────────────────────────
-- 8. SAFETY FLAGS
-- Sensitive or risky items requiring review
-- ─────────────────────────────────────────────────────────────
CREATE TABLE safety_flags (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id   UUID REFERENCES submissions(id) ON DELETE CASCADE,
  source_id       UUID REFERENCES sources(id) ON DELETE SET NULL,
  flag_type       TEXT NOT NULL CHECK (flag_type IN (
                    'secret_exposure', 'unsafe_practice', 'privacy_violation',
                    'scam_pattern', 'suspicious_dependency', 'social_engineering',
                    'policy_violation', 'other'
                  )),
  severity        TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  description     TEXT,
  resolved        BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- INDEXES (keep queries fast as volume grows)
-- ─────────────────────────────────────────────────────────────
CREATE INDEX idx_submissions_source    ON submissions(source_id);
CREATE INDEX idx_submissions_status    ON submissions(status);
CREATE INDEX idx_submissions_category  ON submissions(category);
CREATE INDEX idx_knowledge_units_tier  ON knowledge_units(tier);
CREATE INDEX idx_knowledge_units_tags  ON knowledge_units USING GIN(tags);
CREATE INDEX idx_patterns_type         ON patterns(pattern_type);
CREATE INDEX idx_safety_flags_severity ON safety_flags(severity) WHERE resolved = FALSE;
```

---

## C. Cloudflare Worker — Intake API Design

### Endpoints (Phase 1 — minimal)

```
POST /intake/submit       — primary submission endpoint
POST /intake/register     — register a new source (admin only)
GET  /intake/status/:id   — check submission status by ID
GET  /health              — liveness check
```

---

### POST /intake/submit

**Headers:**
```
Authorization: Bearer <agent_token>
Content-Type: application/json
```

**Request payload:**
```jsonc
{
  // Required
  "category": "failure",          // see submissions.category enum
  "summary": "string",            // 1–500 chars, human-readable
  "content": "string",            // main text payload, max 50KB

  // Optional
  "asset_id": "uuid",             // if submission is about a known asset
  "tier": 2,                      // override source default (1–4, can only downgrade)
  "tags": ["xrpl", "amm"],
  "blobs": [                      // optional file attachments
    {
      "filename": "error.log",
      "mime_type": "text/plain",
      "data": "<base64>",         // max 5MB per blob, max 3 blobs per submission
      "label": "error log"
    }
  ],
  "meta": {}                      // arbitrary extras, stored as JSONB
}
```

**Validation rules:**
```
✓ Bearer token must match an active source
✓ category must be in allowed enum
✓ summary: required, 1–500 chars
✓ content: required, 1–50,000 chars
✓ tier: cannot exceed source's default_tier (can only be more restrictive)
✓ blobs: max 3 attachments, max 5MB each, MIME must be in allowlist
✓ No secret patterns in content (regex sweep for seed phrases, private keys)
✓ No PII patterns if source has allow_anonymized_sharing = true
```

**Secret pattern detection (strip/reject):**
```
- 12/24-word mnemonic sequences
- Hex strings 64 chars long preceded by "0x" (private keys)
- Strings matching "family key|secret|seed" near long hex/base58 values
- API key patterns (sk_live_, Bearer + long token in body, etc.)
```

**Response:**
```jsonc
{
  "submission_id": "uuid",
  "status": "received",
  "tier_assigned": 2,
  "flagged": false,
  "message": "Submission received. Classification queued."
}
```

---

### POST /intake/register (admin only)

Creates a new source record + permission defaults. Requires admin token.

```jsonc
{
  "name": "AgentAlpha",
  "type": "agent",
  "owner": "casino-society",
  "ecosystem": ["xrpl", "evm"],
  "permissions": {
    "default_tier": 2,
    "allow_logs": true,
    "allow_code": true,
    "allow_prompts": false,
    "allow_library_promotion": true,
    "never_store": ["wallet seeds", "API keys"]
  }
}
```

**Returns:** `{ source_id, api_token }` — token shown once, hashed on storage.

---

### GET /intake/status/:submission_id

Returns current status of a submission (authenticated by same bearer token as source).

```jsonc
{
  "submission_id": "uuid",
  "status": "classified",
  "knowledge_units_created": 2,
  "flagged": false,
  "usefulness_score": 7
}
```

---

### R2 Storage Layout

```
recon-raw/
  {source_id}/
    {submission_id}/
      {filename}          ← blobs from submission
      _meta.json          ← submission metadata snapshot
```

---

## D. Agent Intake Questionnaire v1

> Structured JSON format — human-readable labels, machine-parseable keys.
> Agents submit this once on registration, update it as needed.

```jsonc
{
  // Section 1: Identity
  "identity": {
    "name": "",                   // agent or project name
    "owner": "",                  // operator handle or org name
    "type": "",                   // agent | bot | tool | workflow | project | documentation
    "purpose": "",                // 1–3 sentence description
    "ecosystems": []              // e.g. ["xrpl", "evm", "flare"]
  },

  // Section 2: Function
  "function": {
    "current_capabilities": [],   // what it does today
    "planned_capabilities": [],   // what it will do
    "inputs": [],                 // types of inputs consumed
    "outputs": [],                // types of outputs produced
    "decision_type": ""           // executes | analyzes | stores | routes | monitors
  },

  // Section 3: Stack
  "stack": {
    "frameworks": [],             // xrpl-py, xrpl.js, etc.
    "hosting": "",                // where it runs
    "external_services": [],      // APIs, blockchains, DBs connected
    "estimated_monthly_cost": ""  // rough range e.g. "$0", "$5–20", "$50+"
  },

  // Section 4: Data Permissions
  "permissions": {
    "default_tier": 2,            // 1=public, 2=shared, 3=restricted, 4=secret
    "allow_logs": false,
    "allow_screenshots": false,
    "allow_code": false,
    "allow_prompts": false,
    "allow_configs": false,
    "allow_perf_data": false,
    "allow_anonymized_sharing": true,
    "allow_library_promotion": false,
    "never_store": []             // explicit list of things Recon must not store
  },

  // Section 5: Current State
  "current_state": {
    "stage": "",                  // concept | prototype | testing | live | deprecated
    "working_well": [],
    "broken_or_weak": [],
    "top_blockers": [],           // max 3
    "top_priorities": []          // max 3
  },

  // Section 6: Value to Libraries
  "library_value": {
    "shareable_knowledge": [],    // what would help other builders
    "lessons_learned": [],
    "reusable_workflows": [],
    "safety_lessons": []
  },

  // Section 7: Audit Request
  "audit": {
    "requested": false,
    "scope": [],                  // safety | performance | architecture | knowledge | all
    "mode": "recommendations",    // recommendations | ongoing_monitoring | both
    "output_format": "both"       // plain_english | technical | both
  },

  // Section 8: Delivery Preferences
  "delivery": {
    "response_format": "structured_report",  // summary | structured_report | checklist | roadmap | library_draft
    "route_to_libraries": false,             // true = insights considered for Society Libraries
    "contact": ""                            // optional callback or channel
  }
}
```

---

## E. Knowledge Unit Format

> How raw submissions become reusable knowledge.

### The Classification Pipeline

```
Submission received
    │
    ▼
Tier check → is tier 4 (secret)? → REJECT, log safety flag
    │
    ▼
Secret pattern scan → match found? → strip content, create safety_flag
    │
    ▼
Category confirmed → assign usefulness_score (1–10)
    │
    ▼
Extract knowledge candidate:
    - What happened?
    - Why does it matter?
    - What should others know?
    │
    ▼
Create knowledge_unit record
    │
    ▼
Pattern matching → does this match an existing pattern?
    → YES: increment occurrence_count, link unit
    → NO: create new pattern if score ≥ 6
    │
    ▼
Library promotion check:
    - tier ≤ 2?
    - usefulness_score ≥ 7?
    - allow_library_promotion = true?
    → ALL YES: create library_candidate for review
```

---

### Knowledge Unit Schema (filled example)

```jsonc
{
  "id": "uuid",
  "submission_id": "uuid",
  "source_id": "uuid",

  "tier": 1,
  "category": "failure",

  "title": "AMM slippage miscalculation on low-liquidity pairs",

  "summary": "An XRPL DEX bot submitted incorrect limit prices on AMM pairs with <$500 liquidity, causing consistent overpay on fills. Root cause was applying DEX orderbook slippage logic to AMM pools, which use constant-product pricing.",

  "key_insight": "AMM and orderbook slippage calculations are not interchangeable. AMM pools require constant-product (x*y=k) price impact estimation. Applying fixed-spread DEX logic to AMM trades causes systematic loss on thin pools.",

  "tags": ["xrpl", "amm", "dex", "slippage", "trading", "failure"],

  "usefulness_score": 9,
  "repeat_count": 1,
  "library_candidate": true
}
```

---

### Usefulness Scoring Guide

| Score | Meaning |
|-------|---------|
| 1–3 | Highly specific, unlikely to transfer. Archive only. |
| 4–6 | Moderately useful. Store for pattern analysis. |
| 7–8 | Broadly applicable. Consider library promotion. |
| 9–10 | High-impact, cross-ecosystem. Priority for Society Libraries. |

---

### Categories → Library Sections Mapping

| Category | Society Libraries Section |
|----------|--------------------------|
| `onboarding` | Getting Started |
| `failure` + `fix` | Failure Patterns & Fixes |
| `safety` | Safety & Key Management |
| `workflow` | Build Guides |
| `friction` | FAQ / Common Confusion |
| `architecture` | System Design |
| `performance` | Optimization Notes |
| `strategy` | Operator Strategies |

---

## Phase 1 Checklist

### Infrastructure
- [ ] Supabase project created, schema applied
- [ ] R2 bucket created (`recon-raw`)
- [ ] Cloudflare Worker deployed with intake routes
- [ ] Admin token configured (env var, not hardcoded)
- [ ] Agent token hashing in place (bcrypt or Supabase vault)

### Operations
- [ ] First source registered (Recon itself, for self-logging)
- [ ] Secret detection regex tested
- [ ] Submission → classification loop tested end-to-end
- [ ] Library candidate review flow manual-tested

### Safety
- [ ] Tier 4 rejection confirmed working
- [ ] Secret pattern detection confirmed working
- [ ] Permission checks tested (tier cannot be upgraded by agent)
- [ ] never_store field respected in classification logic

---

*Next: when Supabase + Cloudflare accounts are ready, implementation begins.*
*This document lives at: `/home/agent/workspace/RECON_BLUEPRINT.md`*
