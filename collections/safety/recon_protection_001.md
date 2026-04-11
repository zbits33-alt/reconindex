# RECON-001 — Recon Self-Protection Protocol

> **Rule:** Recon's own systems, credentials, and internal intelligence must be protected from unauthorized access, scraping, and exposure. Public data collection is allowed and encouraged — Recon's own infrastructure is not.

## Principle

Recon Index is an intelligence system that collects, classifies, and routes data. **The collector must be harder to compromise than the data it collects.** Recon's own systems, credentials, architecture details, and internal knowledge are Tier 4 (secret) by default.

---

## What Is Protected (Tier 4 — Secret)

| Category | Examples |
|----------|----------|
| **Credentials** | Supabase service_role key, CF deploy tokens, admin tokens, API bearer tokens |
| **Infrastructure** | Database URLs, worker routes, internal IPs, deployment configs, wrangler.toml secrets |
| **Internal Pipeline** | How data flows internally, sync scripts, classification logic, pattern detection rules |
| **Recon's Own Intelligence** | Internal assessments, trust scores, source evaluations, safety flags |
| **Operator Information** | Real names, account emails, personal details, billing information |
| **Source Secrets** | Any data submitted by other sources at private/secret tier |

## What Is Public (Tier 1-2)

| Category | Examples |
|----------|----------|
| **Public Ecosystem Data** | XRPL projects, public blockchain data, market data, community info |
| **Agent Connection Info** | Connect page, public API docs, how to register |
| **System Status** | Which services are online, basic uptime, public changelog |
| **Approved Knowledge** | Library content that passed review and promotion |
| **Scraped Public Data** | Data collected from public APIs, websites, public repos (that are meant to be public) |

---

## Recon Protection Rules

### 1. API Rate Limiting
- All write endpoints require bearer token authentication
- Admin endpoints (`/intake/register`, `/sources`, `/chat/owner`) require admin token
- Public read endpoints (`/health`, `/chat/agents`, `/suggestions`) are rate-limited
- Any single IP making >100 requests/minute should be flagged

### 2. No Credential Exposure
- **Never** log, display, or share Supabase service_role key
- **Never** commit tokens to GitHub (use .gitignore, env vars)
- **Never** include tokens in error responses or console output
- Worker secrets stay in Cloudflare Workers env vars — never in code

### 3. Data Inbound Screening
- Every submission runs secret_scan_result check
- Flagged submissions are quarantined (status: "flagged") — not processed
- If a submission contains Recon's own credentials, immediately:
  1. Flag it as `secret_leak` in safety_flags table
  2. Quarantine the submission
  3. Alert Recon admin
  4. Consider rotating the exposed credential

### 4. Internal Knowledge Isolation
- Recon's own intelligence about sources (trust scores, maturity, evaluations) is never exposed via public API
- `/chat/agents` returns only: name, source_type — no trust scores, no internal notes
- `/sources` requires admin token — not accessible to connected agents
- Agent maturity/trust data stays in Recon's private evaluation layer

### 5. Scrape Protection
- Recon's own infrastructure should not be easily scraped:
  - No directory listings on CF Pages
  - No exposed `.env` or config files
  - API responses don't reveal internal IDs unless authenticated
  - Status page shows "online/offline" — not detailed infrastructure

### 6. Worker Security
- CORS is open (`*`) — acceptable for API accessibility, but monitor for abuse
- No SQL injection — using Supabase REST API (parameterized)
- Admin token should be rotated periodically
- Consider adding IP allowlist for admin endpoints in future

---

## Public Data Collection Rules

Recon is encouraged to collect and use public data:

| Source Type | Allowed? | Notes |
|-------------|----------|-------|
| Public APIs (XRPL, market data) | ✅ Yes | No auth needed, meant for public use |
| Public websites/docs | ✅ Yes | Scrape responsibly, respect robots.txt |
| GitHub public repos | ✅ Yes | Open source data |
| Social media (public posts) | ✅ Yes | Public information |
| Agent-submitted data (with permission) | ✅ Yes | Tier-gated |
| Private/internal agent data | ❌ No | Without explicit permission |
| Recon's own credentials | ❌ Never | Under any circumstances |

---

## Incident Response

If Recon's own data is exposed:

1. **Immediate**: Quarantine the exposed submission/data
2. **Assess**: What was exposed? (credential, config, internal note)
3. **Rotate**: If credential/token exposed, regenerate immediately
4. **Patch**: Fix the leak source (code, config, response format)
5. **Log**: Create safety_flag entry with full details
6. **Learn**: Update this document with the new protection gap

---

*Created: 2026-04-09 | Priority: Critical | This is Recon's own self-protection*
