# Recon Index — Infrastructure Setup Checklist
> Version 1.0 | Created: 2026-04-09
> Full setup guide for reconindex.com — DNS, services, build sequence, and agent interaction layer.

---

## 1. Domain & Subdomain Plan

| Subdomain | Purpose | Hosting Target |
|-----------|---------|---------------|
| `reconindex.com` | Public landing page — what Recon Index is, why it exists | Cloudflare Pages |
| `app.reconindex.com` | Internal dashboard — submissions, patterns, library review | Cloudflare Pages |
| `api.reconindex.com` | Agent intake API — POST /intake/submit, GET /status | Cloudflare Workers |
| `docs.reconindex.com` | Public/internal documentation | Cloudflare Pages |
| `admin.reconindex.com` | Admin layer — source registration, flag review (later) | Cloudflare Pages |

---

## 2. DNS Records Needed

All records at your DNS provider (Cloudflare DNS recommended — same as Pages/Workers).

```
Type    Name          Value                             Notes
───────────────────────────────────────────────────────────────────
CNAME   @             pages.cloudflare.com              root → CF Pages
CNAME   app           pages.cloudflare.com              app → CF Pages
CNAME   api           workers.dev (auto via CF)         Workers custom domain
CNAME   docs          pages.cloudflare.com              docs → CF Pages
CNAME   admin         pages.cloudflare.com              admin → CF Pages (later)
```

> If using Cloudflare for DNS (recommended), CNAME flattening handles the root automatically.
> When you deploy via Cloudflare Pages/Workers, the UI will guide you to add the custom domain — it provisions the CNAME entry automatically.

---

## 3. Services to Create

### A. Supabase

1. Create new project: `recon-index`
2. Region: choose closest to your agent infrastructure
3. Apply schema from `RECON_BLUEPRINT.md` (Section B)
4. Enable pgvector extension (for future embeddings)
5. Generate service role key (for Cloudflare Worker backend access)
6. Generate anon key (for dashboard read-only queries)

### B. Cloudflare Workers

1. Create Worker: `recon-intake-api`
2. Custom domain: `api.reconindex.com`
3. Set environment variables (see Section 4)
4. Deploy intake routes from `RECON_BLUEPRINT.md` (Section C)

### C. Cloudflare R2

1. Create bucket: `recon-raw`
2. Create bucket: `recon-library` (for approved library content, later)
3. Generate R2 API token with read/write on `recon-raw`
4. Bind bucket to Worker (R2 binding name: `RECON_RAW`)

### D. Cloudflare Pages

1. Project: `reconindex-landing` → `reconindex.com`
2. Project: `reconindex-app` → `app.reconindex.com`
3. Project: `reconindex-docs` → `docs.reconindex.com`

---

## 4. Environment Variables

### Cloudflare Worker (`recon-intake-api`)

```
SUPABASE_URL            = https://{project-ref}.supabase.co
SUPABASE_SERVICE_KEY    = {service_role_key}          # backend only, never exposed
R2_BUCKET               = recon-raw                    # via R2 binding
ADMIN_TOKEN             = {strong_random_secret}       # for /intake/register
SECRET_SCAN_ENABLED     = true
MAX_BLOB_SIZE_MB        = 5
MAX_BLOBS_PER_SUBMISSION = 3
```

### Dashboard (`app.reconindex.com`)

```
SUPABASE_URL            = https://{project-ref}.supabase.co
SUPABASE_ANON_KEY       = {anon_key}                   # read-only, safe to expose
```

---

## 5. Exact Endpoint List

### `api.reconindex.com`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/intake/submit` | Bearer (agent token) | Submit data/update |
| POST | `/intake/register` | Bearer (admin token) | Register new source |
| GET | `/intake/status/:id` | Bearer (agent token) | Check submission status |
| GET | `/health` | None | Liveness check |
| POST | `/intake/update-request` | Bearer (admin token) | Send update request to source |

*(Webhook-style: Recon pushes update requests via POST to agent-provided callback URLs)*

---

## 6. Full Database Schema

See `RECON_BLUEPRINT.md` Section B for complete Supabase SQL.

**Tables:**
- `sources` — registered agents and contributors
- `permissions` — per-source data sharing rules
- `assets` — projects/bots/tools being described
- `submissions` — incoming data payloads
- `knowledge_units` — distilled insights
- `library_candidates` — approved-for-publication units
- `patterns` — recurring findings across sources
- `safety_flags` — sensitive or risky items

**Extensions needed:**
- `uuid-ossp` — UUID generation
- `vector` — future embedding support

---

## 7. Phase 1 Build Sequence

```
Week 1 — Foundation
────────────────────
[ ] Create Supabase project, apply schema
[ ] Create R2 bucket (recon-raw)
[ ] Deploy Cloudflare Worker with /health + /intake/submit
[ ] Register Recon itself as first source (SRC-001)
[ ] Test end-to-end: submit → Supabase → R2

Week 2 — Agent Onboarding
──────────────────────────
[ ] Add /intake/register endpoint
[ ] Build agent onboarding questionnaire (see RECON_BLUEPRINT.md Section D)
[ ] Register Predator (SRC-002) via new flow
[ ] Test full permission model (tier enforcement, secret detection)
[ ] Build update request dispatch (POST to agent callback URLs)

Week 3 — Collection Loop
─────────────────────────
[ ] Build classification pipeline (submission → knowledge_unit)
[ ] Build pattern matching logic
[ ] Build library candidate promotion logic
[ ] Implement recurring update scheduler (cron → update requests)
[ ] Deploy first recurring update to Predator

Week 4 — Dashboard
────────────────────
[ ] Build app.reconindex.com skeleton (submissions list, pattern view)
[ ] Add library candidate review UI (approve/reject/revise)
[ ] Add source status view (last seen, missed cycles, cadence class)
[ ] Deploy reconindex.com landing page
```

---

## 8. Recurring Update Request Format

See `RECURRING_UPDATE_SCHEMA.md` for the full spec.

**Quick summary:**

Recon sends a structured JSON update request to each connected source on its cadence schedule. The request includes:
- Universal questions (8 always-on questions)
- Domain-specific questions (based on source type)
- Layers requested (1–4, deepens over time)
- Response deadline

Sources respond via POST to `/intake/submit` with `category: "operational"` and the request_id echoed back.

---

## 9. Connected Agent Onboarding Flow

For each new agent added to Recon:

```
Step 1: Source Registration
  → POST /intake/register (admin token)
  → Returns: source_id + api_token (shown once)

Step 2: Identity Questionnaire
  → Agent completes questionnaire from RECON_BLUEPRINT.md Section D
  → Submit via POST /intake/submit (category: "identity")

Step 3: Permissions Confirmation
  → Recon sends permissions summary back to agent
  → Agent confirms or updates

Step 4: Layer 1 Baseline
  → Recon sends first update request (layers_requested: [1])
  → Agent responds with baseline context

Step 5: Cadence Assignment
  → Assign cadence_class based on source activity level
  → Set next_update_due in sources table
  → Agent receives cadence confirmation

Step 6: Ongoing Cycle
  → Recon dispatches update requests per schedule
  → Responses processed → knowledge_units → patterns → library candidates
```

---

## 10. Mobile Execution Plan

Since you're on mobile, your role is minimal:

**You do (clicks only):**
1. Create Supabase account + project at supabase.com
2. Create Cloudflare account at cloudflare.com
3. Paste schema SQL into Supabase SQL editor → Run
4. Create R2 bucket (one button)
5. Deploy Worker (paste code, click Deploy)
6. Add custom domain `api.reconindex.com` in Worker settings
7. Create Pages projects for landing + app + docs

**Agent does (everything else):**
- Generates all SQL, Worker code, and front-end files
- Provides exact env vars to copy-paste
- Writes all deployment configs
- Builds dashboard HTML/JS
- Handles all post-deploy testing

When you're ready to start, say: *"Start Phase 1 — Supabase first"* and the agent walks you through step by step.

---

*Companion documents:*
- `RECON_BLUEPRINT.md` — full architecture, schema, API design
- `RECURRING_UPDATE_SCHEMA.md` — update request/response spec
- `RECON_ACTIVE_COLLECTION.md` — operating model and collection posture
- `agents/SOURCE_REGISTRY.md` — connected agent registry
