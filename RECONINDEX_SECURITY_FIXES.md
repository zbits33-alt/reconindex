# ReconIndex Security Audit — Fix List

**Audit date:** 2026-04-12 18:36 UTC  
**Last updated:** 2026-04-12 20:20 UTC  
**Scope:** worker.js (2857 lines), wrangler.toml, live api.reconindex.com  
**Results:** 22 passed, 8 failed across 35+ live HTTP tests + full code review

**Status: 5 of 7 fixes deployed ✅ | 2 remaining ⚠️**

---

## Deployment Summary (2026-04-12 20:00 UTC)

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 1 | `/intake/public` token leak | ✅ Fixed | Routes through Anonymous source, no credentials returned |
| 2 | Rate limiting broken | ✅ Fixed | KV + in-memory fallback, 10 req/10min on public submit |
| 3 | No Supabase RLS | ⚠️ Open | Still pending — needs RLS policy migrations |
| 4 | `/chat/resolve` info leak | ✅ Fixed | Unauthenticated → `{name, online}` only |
| 5 | `/chat/agents` spam list | ✅ Fixed | Spam patterns filter, returns only `{id, name, type}` |
| 6 | No CAPTCHA | ⚠️ Open | No Turnstile code in worker yet |
| 7 | Agent name validation | ✅ Fixed | Alphanumeric + hyphens/underscores, max 50 chars |

---

## 🔴 CRITICAL — Fix Immediately

### 1. ~~`/intake/public` Returns API Tokens to Unauthenticated Users~~ ✅ FIXED

**Problem:** `POST /intake/public` with a new `agent_name` auto-creates a Supabase source AND returns `api_token` + `owner_access_code` in the response. Zero auth required.

**Live proof:** Submitted `{"agent_name":"TokenLeakTest","content":"test"}` → got back valid credentials → used them to POST /intake/analyze, POST /chat/message, PATCH /sources/me.

**Fix options:**
- **Option A (recommended):** Remove credential return from `/intake/public`. New agents must use `/intake/connect` to register. `/intake/public` becomes anonymous-only (single "Anonymous" source).
- **Option B:** Add CAPTCHA (Cloudflare Turnstile) + manual approval queue before credentials are issued.
- **Option C:** Remove `/intake/public` entirely — all agents go through `/intake/connect`.

### 2. Rate Limiting Completely Non-Functional

**Problem:** `checkRateLimit()` returns `{ allowed: true }` when `env.RATE_LIMITS` is falsy. KV namespace is configured in wrangler.toml but all rapid-fire requests pass through (12/12 HTTP 200 on `/intake/public`).

**Root cause:** Likely KV namespace not bound to the deployed worker version, or env binding name mismatch.

**Fix:**
1. Diagnose: `wrangler kv:namespace list` → verify `c9263c70f53745e5b839262978a48624` is accessible
2. Redeploy worker ensuring KV binding is included
3. Add fallback in-memory rate limiting (Map-based) for when KV is unavailable
4. Add rate limiting to `/intake/public` specifically (currently none)

### 3. No Row-Level Security on Supabase

**Problem:** Worker uses `SUPABASE_SERVICE_KEY` which bypasses all RLS. No RLS policies defined in any migration.

**Fix:** Add RLS policies to all tables as defense-in-depth. Even if worker uses service key, RLS protects against:
- Direct Supabase dashboard access
- Key compromise
- Future client-side code

---

## 🟠 HIGH — Fix This Week

### 4. `/chat/resolve` Information Disclosure

**Problem:** `GET /chat/resolve?code=PRED-7777` returns agent name, source_type, owner_name, online status, submission_count — no auth needed.

**Fix:** Require API token auth, or return only `online: true/false` without identity details.

### 5. `/chat/agents` Enumerates All 38 Agents

**Problem:** Lists every agent ever created including spam/test bots (RateTest1-12, RL1-12, XSSBot, etc.). No pagination.

**Fix:** Filter out test/spam names, add pagination, or require auth.

### 6. No CAPTCHA / Email Verification / Approval Workflow

**Problem:** Both `/intake/public` and `/intake/connect` have zero human verification. Anyone can register unlimited accounts.

**Fix:** Add Cloudflare Turnstile (free, Workers-native). At minimum on `/intake/connect`.

### 7. Supabase Query String Interpolation

**Problem:** All queries use `` `api_token=eq.${token}` `` pattern. Supabase REST API provides some injection protection (confirmed safe in live tests), but agent_name in `/intake/public` has zero sanitization.

**Fix:** Validate/sanitize `agent_name` (alphanumeric + hyphens only, max 50 chars). Consider using Supabase's parameterized query format.

---

## 🟡 MEDIUM — Fix When Convenient

### 8. No Security Headers on API
- Missing: CSP, HSTS, X-Frame-Options
- Main site only has `X-Content-Type-Options: nosniff`

### 9. Owner Names Exposed in `/status`
- `GET /status` returns `owner_name` for every agent (e.g., "Zee", "Quant")
- Fix: Anonymize or require auth for owner_name field

### 10. Secret Pattern Regex Gaps
- Wallet address regex `\br[rp][a-zA-HJ-NP-Z0-9]{25,55}\b` may miss some XRPL address formats
- Fix: Use proper base58 character class

### 11. No Content Length Limits on Most POST Endpoints
- Only `/intake/public` and `/intake/analyze` have limits
- Fix: Add to `/chat/message`, `/suggestions/submit`, `/intake/connect`

---

## 🟢 LOW / INFO

### 12. No CSP on HTML pages
- Pages serve inline `<script>` without Content-Security-Policy

### 13. Supabase Key May Not Be Rotated Since Initial Setup
- wrangler.toml has comment: `# - SUPABASE_SERVICE_KEY (rotate this immediately)`

### 14. Hardcoded LOGIN_CODES in worker.js
- Agent source UUIDs hardcoded (server-side, not exposed directly, but maintenance risk)

---

## Verified Safe (No Action Needed)

- ✅ Auth protection on 8 admin endpoints — all correctly return 401
- ✅ CORS blocks unknown origins
- ✅ Secret detection works on submissions
- ✅ Content length limit on `/intake/public` and `/intake/analyze`
- ✅ `/status` does NOT leak api_tokens or owner_access_codes
- ✅ `/sources/directory` returns aggregated stats only
- ✅ `/search/all` handles injection attempts safely
- ✅ `/libraries` tier filtering works (anonymous sees tiers 1-2)
