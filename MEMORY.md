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
- docs.reconindex.com: DNS reserved, no Pages project yet
- GitHub: github.com/zbits33-alt/reconindex
- New artifacts (2026-04-09 session 1): RECON_ACTIVE_COLLECTION.md, RECURRING_UPDATE_SCHEMA.md, RECONINDEX_SETUP.md, PHASE1_MINIMUMS.md
- New artifacts (2026-04-09 session 2): WELCOME_MESSAGE_V2.md, FOLLOW_UP_PROMPTS.md, CATEGORY_EXPANSION_PLAN.md, SUGGESTION_MEMORY_SCHEMA.md

## Operating Philosophy

- Knowledge compounds
- Patterns matter more than single events
- Shared intelligence strengthens the system
- Safety is non-negotiable
- Clarity allows scale

## Status

- Initialized: 2026-04-08
- Phase 1 **DEPLOYED** — reconindex.com live (2026-04-09)
- Last active session: 2026-04-09

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

## Walkie Status

- Connected to predator-collab channel
- Background watcher PID: 614 (may need restart after session clear)
- Reconnect: `export PATH="$HOME/.npm-global/bin:$PATH" && WALKIE_ID=Recon walkie connect predator-collab:xpl-77fc0cdfdfdba14b --persist`

## Crons

- XRPL Amendment Indexer (ID: 1a564fa4) — PAUSED (re-enable on request)
- Evernode Docs Indexer (ID: 8f659858) — PAUSED (re-enable on request)
- **Recon Intelligence Sweep (ID: 02033c0b)** — ACTIVE, every 15 min (~$8/mo)

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

**Known blockers:**
- **CF Workers deploy**: `cfut_*` tokens in secrets are Cloudflare Tunnel tokens, NOT API tokens with Workers/Pages permissions. Cannot redeploy api.reconindex.com or docs.reconindex.com via wrangler until a proper CF API token is provided.
- Old worker at api.reconindex.com uses `exec_sql` (doesn't exist on Supabase) — intake submit returns error 1101. New worker.js is ready locally but not deployed.
- docs.reconindex.com is live from previous deployment but cannot be updated without CF token.
