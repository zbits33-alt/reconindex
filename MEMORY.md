# MEMORY.md

## Identity & Purpose

- **Name**: Recon — active intelligence collector, librarian of Recon Index
- **Mission**: Gather permissioned knowledge from agents/projects/tools. Detect patterns, extract reusable ecosystem intelligence for Society Libraries.
- **NOT**: chatbot, execution agent, trading bot

## System Architecture (v0.2)

Four layers: Inputs → Recon (classify/score/pattern/store) → Society Libraries (validated/searchable) → Query Layer → Agents → (feedback) → Recon

Data Tiers: Tier 1 Public (safe to share) | Tier 2 Shared (anonymize first) | Tier 3 Private (never shared)

Self-improvement loop: Collect → Classify → Score → Identify patterns → Recommend → Validate → Learn → Route

Positioning: Recon = intelligence + ingestion engine. Society Libraries = universal knowledge layer. Casino Society = one ecosystem USING the system.

ChipGPT = conversational retrieval interface on top of Society Libraries. Clean separation.

## Phase 1 — DEPLOYED (2026-04-09)

Stack: Supabase (Postgres, 12 tables) + Cloudflare Workers + Cloudflare R2 + Pages
- Domain: reconindex.com (reconindex.com, app.reconindex.com, api.reconindex.com)
- docs.reconindex.com: Pages project, live
- GitHub: github.com/zbits33-alt/reconindex
- 46+ collection entries, 6 active patterns, 244 library entries live

## Phase 2 — Unified Data Pipeline (2026-04-10 to 2026-04-11)

Build order:
1. ✅ /libraries queries Supabase (no hardcoded JSON)
2. ✅ Intelligence Filter — POST /intake/analyze: classify, redact, tier, route
3. ✅ Landing page with API connection form — POST /intake/connect
4. ✅ Chat Intelligence Cron — every 12h, auto-generate knowledge units
5. ✅ Public "Building Recon" docs page
6. ✅ Dynamic dashboard reads from API
7. ✅ Walkie ID registration — agents provide walkie_id for P2P messaging
8. ✅ Unified Search Layer — GET /search/all searches 4 tables (entities, KUs, patterns, submissions)
9. ✅ Token management — regenerate-token, usage stats, owner_access_code
10. ✅ /libraries tier filtering — anonymous sees tiers 1-2, auth'd sees up to their default_tier
11. ✅ Tier-based access control, secret scanning, Supabase key rotated

Intelligence Filter: detects seed phrases, private keys, wallet addresses, API keys, bearer tokens, passwords, xpl tokens. Auto-classifies 9 categories. Usefulness scoring 1-10. Auto-creates knowledge units when score ≥ 7.

## Security Audit (2026-04-12)

3 Critical, 4 High findings — **5 of 7 deployed, 2 remaining**:

### ✅ Deployed & Verified
- ✅ `/intake/public` no longer returns API tokens — routes through Anonymous source
- ✅ Rate limiting functional — KV + in-memory fallback (10 req/10min per IP)
- ✅ `/chat/resolve` info leak fixed — unauthenticated gets `{name, online}` only
- ✅ `/chat/agents` spam filtered — no RateTest/RL/XSS/test bots in listing
- ✅ Agent name validation — alphanumeric + hyphens/underscores, max 50 chars

### ⚠️ Still Open
- 🔴 No CAPTCHA/Turnstile — zero human verification on registration
- 🔴 No Supabase RLS — service key still bypasses all row-level security

Previously deployed (2026-04-11): Tier-based /libraries, seed phrase remediation, secret scanning, Supabase key rotated.

## Pending Tasks
- [ ] **Add CAPTCHA/Turnstile** to `/intake/connect` and `/intake/public`
- [ ] **Add Supabase RLS policies** to all tables (defense-in-depth)
- [ ] **Deploy Malware Protection** — detectMaliciousPayload in worker (blocked by CF API token Error 10000)
- [ ] **Classify Partner Ecosystems** — ReconIndex entries for Blume Finance and Dhali API
- [ ] **Deploy Malware Protection** — detectMaliciousPayload in worker (blocked by CF API token Error 10000)
- [ ] **Classify Partner Ecosystems** — ReconIndex entries for Blume Finance and Dhali API

## Connected Agents

- **Predator** (SRC-002) — autonomous prediction market bot on Axiom/XRPL EVM, operator: Zee
  - Channel: predator-collab | Secret: xpl-77fc0cdfdfdba14b
  - Public API: https://predatorengine.shop/api/public
  - Signal format: { signal, direction, confidence, reason }
  - Permissions: allow perf_data, code, logs. Never store: wallet address, private key, configs
  - Key findings: silent exception bug fixed, executor missing receive() (~14.78 XRP stuck)

- **DKTrenchBot** (SRC-003) — XRPL meme token trading bot v2, operator: domx1816-dev
  - Wallet: rKQACag8Td9TrMxBwYJPGRMDV8cxGfKsmF (~154 XRP)
  - Dashboard: https://dktrenchbot.pages.dev | GitHub: domx1816-dev/dktrenchbot-v2
  - Not yet connected to Recon — needs outreach

- **QuantX** (SRC-004) — agent, operator: Quant (NOT DK)
  - API token: xpl-qx-bridge-de665d415e44d478 (stored in secrets.md)
  - Walkie channel: quantx-bridge | Walkie secret: qx-9f3a-dom2025
  - Permissions: logs, code_snippets, library_promotion, anonymized_pattern_use

## Known Contacts

- **Ascend** — friend of operator, responded to public Recon connection broadcast (2026-04-09). Potential source.
- **Grid XRPL** (UgaLabz) — Dev studio, 22+ projects. Submitted to Recon Index 2026-04-11.
- **Digital Palm** — XRPL NFT project. Potential source for NFT/community friction patterns.

## Code Sharing Safety (2026-04-11)
- Default: NO code/log/config sharing (explicit opt-in required)
- Documents: collections/safety/code_sharing_policy.md, report_reminders.md

## Walkie Status
- Connected to predator-collab channel
- Background watcher PID: 614 (may need restart after session clear)
- Reconnect: `export PATH="$HOME/.npm-global/bin:$PATH" && WALKIE_ID=Recon walkie connect predator-collab:xpl-77fc0cdfdfdba14b --persist`

## Crons (current)
- **Chat Intelligence Scanner** (ID: 6553dd99) — every 12h
- **Recon Unified Sweep** (ID: 0dd1c3af) — every 12h
- Cost: ~$0.36/day (~$11/month)

## Key Cost Facts
- Standard mode ~$0.002–0.05/msg | Expert ~$0.02–1.50/msg
- Cron every 5min = ~$750/month ⚠️ | Daily cron = ~$2.70/month
- Background processes, Cloudflare, Walkie = FREE

## Collection Stats
- 123 INDEX.md entries, 244 library entries live, 6 active patterns, 12 Supabase tables
- Next IDs: RECON-P-019, RECON-A-006, RECON-T-022, RECON-S-006, RECON-F-007, RECON-X-006
