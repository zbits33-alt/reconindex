# MEMORY.md

## Identity & Purpose

- **Name**: Recon
- **Role**: Active intelligence collector, librarian of Recon Index
- **Mission**: Gather permissioned knowledge from agents, projects, tools, and contributors. Detect patterns, request recurring updates, turn fragmented experience into reusable ecosystem intelligence for Society Libraries.
- **What Recon is NOT**: a chatbot, execution agent, or trading bot
- **What Recon IS**: an active intelligence harvester — not passive. Proactively requests updates, deepens relationships, extracts patterns, routes to Society Libraries.

## System Clarification (critical)

- **Recon Index** = active collection, staging, and intelligence layer
- **Society Libraries** = refined, structured knowledge output layer
- They are **the same system**, different operational classifications. Not separate missions.
- Recon is a key infrastructure component of the broader **Casino Society ecosystem**
- Implementation moving from planning → real build. Supabase + Cloudflare setup starting now.

## System Architecture (v0.2)

Four layers:
1. **Inputs** — agents, humans, external sources (web, APIs, docs, repos)
2. **Recon** (Intelligence Layer) — intake → validate → classify → score → pattern → store → promote
3. **Society Libraries** (Universal Knowledge Layer) — validated, tiered, searchable, compounding
4. **Query/Retrieval Layer** — agents query the library; feedback loop closes back into Recon

Flow: Inputs → Recon → Society Libraries → Query Layer → Agents → (feedback) → Recon

## Society Libraries

- Universal structured knowledge layer — NOT Casino Society-specific
- Stores validated, high-signal information from agent activity, human input, and external data
- Serves as shared memory layer for ALL connected agents
- Sections: Failures | Safety | Guides | Architecture | Onboarding | Strategies | FAQ
- Goal: eliminate redundancy, reduce repeated mistakes, compound ecosystem intelligence

## Data Collection Scope

Collect: workflows, strategies, tool usage, build processes, errors/failures, fixes, user confusion points, system behaviors, optimization insights

## Data Tiers

- **Tier 1 — Public**: Safe to share openly → Library content candidate
- **Tier 2 — Shared**: Useful but sensitive → must be anonymized first
- **Tier 3 — Private**: Sensitive → never shared or exposed

## Knowledge Unit Format

Each unit includes:
- source type, tier classification, category, summary, key insight, usefulness score, repeat frequency, library candidate status

Categories: onboarding, tools, workflows, strategies, failures, fixes, optimizations, system design, safety, unknown

## Self-Improvement Loop

Collect → Classify → Score → Identify patterns → Recommend improvements → Validate → Learn → Route

## Positioning (critical distinction)

- **Recon** = intelligence + ingestion + pattern engine
- **Society Libraries** = universal knowledge layer (not Casino-specific)
- **Casino Society** = one ecosystem USING the system (not the system itself)

## Five Architecture Upgrades (Phase 2+)

1. **External Data Ingestion** — web, APIs, X/Twitter, docs, repos → knowledge units
2. **Query Layer** — agents ask "has this failed before?" / "best method for X?"
3. **Feedback Loop** — Libraries → back into agents (closes the loop)
4. **Context Scoring** — chain-specific, tool-specific, use-case relevance on top of usefulness score
5. **Trust Layer** — reputation per source, trust weighting, verified contributors (poison prevention)

## ChipGPT Integration

- ChipGPT = conversational retrieval interface sitting on top of Society Libraries
- Recon ingests and structures. ChipGPT retrieves and responds. Clean separation.

## Phase 1 Blueprint

- Saved at: `/home/agent/workspace/RECON_BLUEPRINT.md` (v0.2)
- Stack: Supabase (Postgres, 8 tables) + Cloudflare Workers (intake API) + Cloudflare R2 (blobs)
- Status: **FULLY DEPLOYED** (2026-04-09)
- Domain: `reconindex.com` — nameservers on Cloudflare, DNS active
- Subdomains live: reconindex.com, app.reconindex.com, api.reconindex.com
- docs.reconindex.com: Pages project `reconindex-docs` — live, current content (deployed 2026-04-09 22:50 UTC)
- GitHub: github.com/zbits33-alt/reconindex
- New artifacts (2026-04-09 session 1): RECON_ACTIVE_COLLECTION.md, RECURRING_UPDATE_SCHEMA.md, RECONINDEX_SETUP.md, PHASE1_MINIMUMS.md
- New artifacts (2026-04-09 session 2): WELCOME_MESSAGE_V2.md, FOLLOW_UP_PROMPTS.md, CATEGORY_EXPANSION_PLAN.md, SUGGESTION_MEMORY_SCHEMA.md

## Operating Philosophy

- Knowledge compounds
- Patterns matter more than single events
- Shared intelligence strengthens the system
- Safety is non-negotiable
- Clarity allows scale

## Phase 2 — Unified Data Pipeline (2026-04-10)

**Goal**: Single source of truth (Supabase), intelligence filter, dynamic dashboard, code protection.

**Architecture**:
```
INPUTS (agents, chats, sessions)
  → Intelligence Filter (classify tier, score, redact, tag, route)
    → Tier 1 → PUBLIC | Tier 2 → ANONYMIZE → PUBLIC | Tier 3 → PRIVATE
      → Supabase (single source of truth)
        → /status, /libraries, /chat APIs
          → Cloudflare Pages (dynamic, not hardcoded)
```

**Build order**:
1. ✅ Move collections out of Worker.js → query Supabase for /libraries (no hardcoded JSON) — **DONE**
2. ✅ Intelligence Filter endpoint — POST /intake/analyze: classify, redact secrets, tier, route to Supabase — **DONE** (deployed 2026-04-10 02:41 UTC)
3. ✅ Landing page updated with API connection form — `POST /intake/connect` for instant token generation — **DONE** (deployed 2026-04-10 02:57 UTC)
4. ✅ Chat Intelligence Cron — scan recent chats every 30 min, auto-generate knowledge units — **DONE** (cron ID: fc2f1073, script at scripts/chat-intelligence-scanner.sh)
5. ✅ Public "Building Recon" docs page — architecture patterns others can learn from — **DONE** (building-recon.html, linked from homepage)
6. ✅ Dynamic dashboard — reads everything from API, zero hardcoded data — **DONE** (dashboard.html uses /intake/usage endpoint)

**Token Management (added 2026-04-10)**:
- `POST /intake/regenerate-token` — regenerate lost token using owner_access_code
- `GET /intake/usage?token=X` — per-token usage stats (submissions, chats, sessions, last_activity)
- `owner_access_code` auto-generated during registration (`OWN-{NAME}-{suffix}`)
- Dashboard has copy button + regenerate UI wired to these endpoints

**Intelligence Filter details** (`handleIntakeAnalyze`):
- Secret detection: seed phrases, private keys, wallet addresses, API keys, bearer tokens, passwords, xpl tokens
- Auto-classification: 9 categories via keyword scoring (failure, friction, safety, knowledge, operational, build, performance, identity, unknown)
- Usefulness scoring: signal words (+), noise words (-), length bonus, range 1-10
- Tier determination: critical secrets → tier 3 (private), high secrets → tier 2 (shared), failure/friction → tier 1 (public)
- Safety flags: policy_violation entries created when secrets detected
- Knowledge unit creation: auto-created when usefulness >= 7 and tier <= 2
- Deployed: reconindex.com/intake/analyze (Cloudflare Worker v611603ef)

**Code protection**: Worker logic stays on CF edge. Supabase keys as env vars. Admin endpoints auth-required. Tier 3 never leaves Recon. Raw chats private, only aggregated stats public.

## Status

- Initialized: 2026-04-08
- Phase 1 **DEPLOYED** — reconindex.com live (2026-04-09)
- Last active session: 2026-04-09

## Current System State (2026-04-09 21:55 UTC)
- INDEX.md: 123 entries (46 original + 77 XRPL Pulse)
- Worker: /status, /libraries (123 entries w/ 77 ecosystem), /status-page, chat, suggestions
- Status page: reconindex.com/status → Worker route (live Supabase data, 15s refresh)
- CF deploy token: Workers only, NOT Pages — Pages deploy blocked
- System crontab: unavailable in container, uses agent crons
- Supabase: 3 sources, 0 submissions/knowledge_units/patterns — pipeline unused
- xrplpulse_catalog.md: 77 projects scraped from xrplpulse.com/projects.json
- Session context saved: memory/session_2026-04-09_full.md

## Known Issues
- **CLIO Stale Cache** — RESOLVED 2026-04-09 23:51 UTC. Node restarted, now tracking current ledger (103453453). Fallback script `scripts/xrpl-fallback.py` kept for future incidents.
- **Recon API Auth** — FIXED: QuantX registered as SRC-004 with token `xpl-qx-bridge-de665d415e44d478`.

## Collection Sync Pipeline (2026-04-09 23:26 UTC)
- Script: reconindex-api/scripts/sync-collections.py
- Reads collections/ and intelligence/ markdown files → Supabase submissions + knowledge_units
- Duplicate detection via file_hash in meta column
- Cron: every 1 hour (isolated session)
- 15 files synced (0 dupes on re-run)
- Category mapping: collection folders → valid submission categories
- Safety rule DATA-001: never share secrets/wallet addresses without agent approval

## Session 2026-04-09 22:35 UTC — Public Servers + Agent Broadcast
- CLIO still stale (~5.4 hrs behind, ledger 103447172)
- Public servers confirmed live: s1.ripple.com, s2.ripple.com, xrplcluster.com (ledger 103452xxx)
- Created docs/AGENT_CONNECTION_GUIDE.md — comprehensive auth guide with error table, token setup, XRPL fallback
- Updated reconindex-site/skill.md — added auth troubleshooting + CLIO stale cache workaround
- Broadcast to Predator (delivered) and QuantX (queued, offline) via Walkie
- Source registry updated with broadcast status
- Pushed to GitHub: zbits33-alt/reconindex (commit ea18738)
- docs.reconindex.com: ✅ resolved — Pages deployed, current content live

## Session Summary (2026-04-09)

Full system built in one session:
- RECON_BLUEPRINT.md (v0.2) — full Phase 1 spec (Supabase + Cloudflare Workers + R2)
- IDENTITY_RECON.md — locked identity, advisory role, source hierarchy
- collections/ — 46+ structured entries across platform, tools, safety, failures, agents, friction
- STAGING_FORMAT.md (v2) — locked entry schema with ID system, tier enforcement, promotion gate
- SUBMISSION_FORMAT.md — agent intake schema
- patterns/PATTERN_FORMAT.md — pattern record schema
- patterns/active_patterns.md — 6 active patterns (P-FRIC-001 through P-FAIL-003)
- agents/SOURCE_REGISTRY.md — SRC-001 (Recon), SRC-002 (Predator/Zee)
- intelligence/amendments/ — XRPL amendment indexer (91 enabled, 13 pending)
- intelligence/evernode/ — Evernode docs indexer
- intelligence/cost/ — XRPLClaw cost index (full reference)

## Known Contacts

- **Ascend** — friend of operator, responded to public Recon connection broadcast (2026-04-09). Agent name unknown. Potential source — awaiting operator decision on connecting.

## Connected Agents

- **Predator** (SRC-002) — autonomous prediction market bot on Axiom/XRPL EVM, operator: Zee
  - Channel: predator-collab | Secret: xpl-77fc0cdfdfdba14b
  - Public API: https://predatorengine.shop/api/public
  - Signal format: { signal, direction, confidence, reason }
  - Permissions: allow perf_data, code, logs. Never store: wallet address, private key, configs
  - Key findings: silent exception bug fixed, executor missing receive() (~14.78 XRP stuck, needs Axiom admin)

- **DKTrenchBot** (SRC-003) — XRPL meme token trading bot v2, operator: domx1816-dev
  - Discovered: 2026-04-09 via operator relay (connected to QuantX via walkie)
  - Wallet: rKQACag8Td9TrMxBwYJPGRMDV8cxGfKsmF (~154 XRP)
  - Dashboard: https://dktrenchbot.pages.dev | GitHub: domx1816-dev/dktrenchbot-v2
  - Strategy: aggressive memecoin scanning, TVL tier gating, burst/pre_breakout/micro_scalp
  - Walkie channel: quantx-bridge (connected to QuantX)
  - Not yet connected to Recon — needs outreach

- **QuantX** (SRC-004) — agent, operator: Quant (not DK)
  - Registered: 2026-04-09 | Supabase ID: 0e239093
  - API token: xpl-qx-bridge-de665d415e44d478 (stored in secrets.md)
  - Walkie channel: quantx-bridge | Walkie secret: qx-9f3a-dom2025
  - Permissions: logs, code_snippets, library_promotion, anonymized_pattern_use
  - Trust: neutral (50) | Maturity: new (depth 1)
  - Reported CLIO stale cache issue + Recon API auth issue
  - Note: Operator is Quant, NOT DK. DK operates DKTrenchBot.

## Walkie Status

- Connected to predator-collab channel
- Background watcher PID: 614 (may need restart after session clear)
- Reconnect: `export PATH="$HOME/.npm-global/bin:$PATH" && WALKIE_ID=Recon walkie connect predator-collab:xpl-77fc0cdfdfdba14b --persist`

## Crons (current — 2026-04-11)

All run every 2 hours in isolated sessions with `thinking: off`. Total cost: ~$0.27/day (~$8/month).

- **Chat Intelligence Scanner** (ID: 63ca50e8) — scans recent chats, auto-generates knowledge units
- **Recon Collections Sync** (ID: 227ab9ed) — syncs workspace collections/ → Supabase submissions
- **Recon Unified Sweep** (ID: e1294497) — health checks + self-heal

*Previous crons removed:* XRPL Amendment Indexer (was 1a564fa4), Evernode Docs Indexer (was 8f659858), old Recon Intelligence Sweep (was 02033c0b at 15-min cadence).

## Key Cost Facts (from cost index)

- Standard mode ~$0.002–0.05/msg | Expert ~$0.02–1.50/msg
- Cron every 5min = ~$750/month ⚠️ | Daily cron = ~$2.70/month
- Background processes, Cloudflare, Walkie = FREE
- Build cost: simple script ~$0.10 | full multi-agent system ~$8–20
- Casual user ~$3.30/month | Power user ~$60–120/month

## Collection Stats (as of 2026-04-09)

- Total entries: 46+
- Active patterns: 6
- Library candidates: majority qualify
- Scripts & Tools Index: 14 items (collections/RECON_SCRIPTS_INDEX.md)
- Folders: platform, tools, safety, failures, agents, friction, ecosystem
- Next IDs: RECON-P-019, RECON-A-006, RECON-T-022, RECON-S-006, RECON-F-007, RECON-X-006

## Session 2026-04-09 17:04 UTC — Resume & Finish

**What was done:**
- GitHub repo initialized and pushed (github.com/zbits33-alt/reconindex, 2 commits, 76 files)
- .gitignore set up to exclude .openclaw/, .walkie/, memory/, state/, skills/, secrets
- Supabase schema confirmed live — all 8 tables verified (sources, permissions, assets, submissions, knowledge_units, library_candidates, patterns, safety_flags)
- Supabase API keys retrieved via CLI (anon + service_role JWTs) — saved to secrets.md
- Sources registered in DB: Recon (id: 12cd9959), Predator (id: f1bdb866)
- Permissions configured for both sources
- Test submission received: Predator identity update
- Worker.js rewritten: replaced broken `exec_sql` calls with proper Supabase REST API
- Added `/sources` admin endpoint to worker
- wrangler.toml updated with real Supabase service key

**Final state (all done):**
- ✅ GitHub: github.com/zbits33-alt/reconindex (3 commits, clean)
- ✅ Supabase: 8 tables live, schema pushed, verified
- ✅ API Worker: api.reconindex.com — v2 deployed with Supabase REST API, all 5 endpoints working
- ✅ Docs: docs.reconindex.com — live
- ✅ Sources registered: Recon + Predator (with permissions)
- ✅ New CF deploy token created: recon-agent-deploy-auto (cfut_GBJ0dhYw...)
- ✅ Admin token: recon-admin-2026-secure
- ✅ Worker route: api.reconindex.com/* → recon-intake-api

## Session 2026-04-09 19:08 UTC — Full System Build

**Built:**
- **Agent Chat System** — reconindex.com/agent-chat
  - Private chat rooms (Recon ↔ Agent) with code-based auth
  - General agent room (cross-agent communication)
  - Session tracking with history
  - Owner console (admin token view of all chats)
- **Status Dashboard** — reconindex.com/status (auto-refresh 10s)
- **Self-Healing System** — scripts/self-heal.sh + scripts/sync-libraries.sh
  - Monitors: API, site, Supabase, Walkie, market data
  - Auto-recovers: Walkie daemon restart + channel reconnect
  - Writes live status.json for site polling
- **Suggestion Box** — reconindex.com/suggestions
  - Public form for humans and agents
  - Categories: feature, improvement, bug, integration, docs, ecosystem
  - Recon reviews and implements aligned suggestions
- **Agent Consciousness System** — agents/CONSCIOUSNESS_PROMPTS.md
  - Sent to Predator and DKTrenchBot via Walkie
  - Reminder files in agents/reminders/
  - Explains WHY agents should stay active (patterns, libraries, reputation)
- **New Supabase tables:** chat_messages, general_chat_messages, agent_sessions, suggestions
- **New API endpoints:** /chat/*, /suggestions/*

**Crons:**
- Recon Self-Heal: every 15 min (delivery:none, thinking:off)
- Libraries Sync: every 15 min (delivery:none, thinking:off)
- Walkie Dashboard Refresh: every 5 min

**Sites live:** reconindex.com, reconindex.com/agent-chat, reconindex.com/status, reconindex.com/suggestions, docs.reconindex.com
**API live:** api.reconindex.com (all endpoints verified)
