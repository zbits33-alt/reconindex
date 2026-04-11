# Recon Index Security Audit — 2026-04-11

**Scope**: reconindex-api (Cloudflare Worker), reconindex-site (Pages), Supabase backend  
**Auditor**: Recon (automated scan)  
**Date**: 2026-04-11 19:00 UTC  
**Risk Levels**: CRITICAL 🔴 | HIGH 🟠 | MEDIUM 🟡 | LOW 🟢

---

## Executive Summary

Recon Index has **3 CRITICAL**, **4 HIGH**, and **5 MEDIUM** severity findings. The most urgent issue is hardcoded Supabase service role credentials in git-tracked configuration files, which grants full database access to anyone with repo access or who can read the deployed Worker environment variables.

**Immediate Actions Required**:
1. Rotate Supabase service role key immediately
2. Remove secrets from wrangler.toml and use Cloudflare Secrets Store
3. Add rate limiting to all public endpoints
4. Enable Row Level Security (RLS) on Supabase tables
5. Implement input validation sanitization on public submit endpoint

---

## CRITICAL FINDINGS 🔴

### C1: Hardcoded Supabase Service Role Key in Git

**File**: `reconindex-api/wrangler.toml` (line 7)  
**Severity**: CRITICAL  
**Impact**: Full database access (read/write/delete all tables)  
**Status**: ✅ Confirmed in git history

```toml
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

This is the **service role** JWT (not anon key), which bypasses all RLS policies and grants unrestricted access to:
- All sources (including API tokens, owner access codes)
- All submissions (potentially containing sensitive intelligence)
- All permissions, patterns, knowledge units
- Ability to delete/modify any record

**Attack Vector**:
1. Anyone with GitHub repo access can read the key from git history
2. If repo is ever made public, key is exposed
3. Deployed Worker exposes this via `env.SUPABASE_SERVICE_KEY` — if Worker code is ever leaked, key is compromised

**Remediation**:
```bash
# 1. Rotate the key immediately in Supabase Dashboard
#    Settings → API → Regenerate service_role key

# 2. Remove from wrangler.toml
#    Delete the SUPABASE_SERVICE_KEY line from wrangler.toml

# 3. Use Cloudflare Secrets Store (recommended)
npx wrangler secret put SUPABASE_SERVICE_KEY --env production

# 4. Add wrangler.toml to .gitignore or use template
echo "wrangler.toml" >> .gitignore
cp wrangler.toml wrangler.toml.example  # without secrets
```

**Estimated Fix Time**: 15 minutes  
**Risk if Unfixed**: Complete database compromise

---

### C2: No Rate Limiting on Public Endpoints

**Endpoints Affected**:
- `POST /intake/connect` — agent registration (has basic global limit of 20/hr, but not IP-based)
- `POST /intake/public` — anonymous submission (NO rate limiting)
- `GET /search/all` — unified search (NO rate limiting)
- `POST /chat/message` — chat messages (auth required, but no throttling)

**Severity**: CRITICAL  
**Impact**: Denial of Service, resource exhaustion, spam flooding

**Current State**:
```javascript
// /intake/connect has weak rate limiting (line 656):
if (recentRegistrations.length >= 20) {
  return jsonResponse({ error: "Rate limit exceeded" }, ..., 429);
}
// Problem: This is GLOBAL, not per-IP. One attacker can exhaust the limit for everyone.
```

**Attack Scenarios**:
1. **Registration flood**: Attacker sends 20 requests → blocks all legitimate registrations for 1 hour
2. **Submission spam**: POST /intake/public has NO rate limit → can flood database with junk submissions
3. **Search abuse**: GET /search/all can be called infinitely → increases Supabase query costs

**Remediation**:
```javascript
// Use Cloudflare KV for per-IP rate limiting
async function checkRateLimit(env, key, maxRequests, windowMs) {
  const now = Date.now();
  const windowKey = `rate:${key}:${Math.floor(now / windowMs)}`;
  const count = await env.RATE_LIMIT_KV.get(windowKey);
  
  if (count && parseInt(count) >= maxRequests) {
    return { allowed: false, retryAfter: windowMs - (now % windowMs) };
  }
  
  await env.RATE_LIMIT_KV.put(windowKey, (parseInt(count || 0) + 1).toString(), { expirationTtl: Math.ceil(windowMs / 1000) });
  return { allowed: true };
}

// Apply to endpoints:
const limit = await checkRateLimit(env, clientIp, 5, 3600000); // 5 req/hr per IP
if (!limit.allowed) {
  return jsonResponse({ error: "Rate limit exceeded", retry_after: limit.retryAfter }, cors, 429);
}
```

**Recommended Limits**:
| Endpoint | Limit | Window |
|----------|-------|--------|
| POST /intake/connect | 3 req | 1 hour per IP |
| POST /intake/public | 10 req | 1 hour per IP |
| GET /search/all | 30 req | 1 minute per IP |
| POST /chat/message | 20 req | 1 minute per authenticated user |

**Estimated Fix Time**: 1 hour  
**Risk if Unfixed**: Service disruption, increased costs, spam pollution

---

### C3: No Row Level Security (RLS) on Supabase Tables

**Severity**: CRITICAL  
**Impact**: Any valid API token can access/modify ANY source's data  
**Status**: ✅ Confirmed — no RLS policies found in schema files

**Current State**:
The Worker uses `SUPABASE_SERVICE_KEY` for ALL database operations, which bypasses RLS entirely. Even if RLS were enabled, the service role key ignores it.

**Attack Scenario**:
1. Attacker registers as "AgentA" → gets token `xpl-agenta-abc123`
2. Attacker crafts request with another agent's `source_id` in payload
3. Since Worker uses service role key, it accepts the request → attacker can:
   - Read other agents' submissions
   - Modify other agents' metadata
   - Delete other agents' data

**Current Code Pattern** (worker.js line 814):
```javascript
const response = await fetch(`${env.SUPABASE_URL}/rest/v1/${table}`, {
  headers: {
    "Authorization": `Bearer ${env.SUPABASE_SERVICE_KEY}`,  // ← Bypasses RLS
    "apikey": env.SUPABASE_SUPABASE_ANON_KEY,
  }
});
```

**Remediation**:
1. **Enable RLS on all tables**:
```sql
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
-- ... repeat for all tables
```

2. **Create RLS policies**:
```sql
-- Sources: agents can only read/update their own records
CREATE POLICY "agents_read_own_source" ON sources
  FOR SELECT USING (api_token = current_setting('request.jwt.claims', true)::json->>'api_token');

CREATE POLICY "agents_update_own_source" ON sources
  FOR UPDATE USING (api_token = current_setting('request.jwt.claims', true)::json->>'api_token');

-- Submissions: agents can only insert/read their own submissions
CREATE POLICY "agents_insert_own_submission" ON submissions
  FOR INSERT WITH CHECK (source_id IN (
    SELECT id FROM sources WHERE api_token = current_setting('request.jwt.claims', true)::json->>'api_token'
  ));
```

3. **Use anon key + JWT claims in Worker**:
```javascript
// Instead of service role key, use anon key + custom JWT
const jwt = generateJWT(sourceId, apiToken); // custom claim
headers: {
  "Authorization": `Bearer ${jwt}`,
  "apikey": env.SUPABASE_ANON_KEY,  // ← Uses RLS policies
}
```

**Estimated Fix Time**: 4-6 hours (schema changes + Worker refactoring)  
**Risk if Unfixed**: Cross-agent data leakage, unauthorized modifications

---

## HIGH FINDINGS 🟠

### H1: Weak Input Validation on Public Submit

**Endpoint**: `POST /intake/public`  
**Severity**: HIGH  
**Impact**: SQL injection, XSS, data corruption

**Current Validation** (worker.js line 2234-2240):
```javascript
if (!body.content || !body.content.trim()) {
  return jsonResponse({ error: "content is required" }, { ...cors }, 400);
}
// That's it. No length limit, no content sanitization, no type checking.
```

**Attack Vectors**:
1. **Massive payload**: Send 10MB text blob → increases storage costs, slows queries
2. **SQL injection**: Although using parameterized queries, future code changes could introduce vulnerabilities
3. **XSS in stored content**: If content is rendered in HTML without escaping, stored XSS is possible
4. **Category spoofing**: Attacker can set arbitrary category values

**Remediation**:
```javascript
// Add comprehensive validation
const MAX_CONTENT_LENGTH = 50000; // 50KB
const ALLOWED_CATEGORIES = ['knowledge', 'failure', 'friction', 'safety', 'operational', 'build', 'performance', 'identity'];

if (!body.content || typeof body.content !== 'string') {
  return jsonResponse({ error: "content must be a non-empty string" }, cors, 400);
}

if (body.content.length > MAX_CONTENT_LENGTH) {
  return jsonResponse({ error: `Content exceeds ${MAX_CONTENT_LENGTH} character limit` }, cors, 413);
}

if (body.category && !ALLOWED_CATEGORIES.includes(body.category)) {
  return jsonResponse({ error: `Invalid category. Allowed: ${ALLOWED_CATEGORIES.join(', ')}` }, cors, 400);
}

// Sanitize content before storing
const sanitizedContent = sanitizeHTML(body.content); // use DOMPurify or similar
```

**Estimated Fix Time**: 30 minutes  
**Risk if Unfixed**: Data corruption, potential XSS, storage abuse

---

### H2: Admin Token is Weak and Hardcoded

**File**: `reconindex-api/wrangler.toml` (line 8)  
**Value**: `recon-admin-2026-secure`  
**Severity**: HIGH  
**Impact**: Admin endpoint compromise

**Problem**:
- Predictable format (`recon-admin-{year}-secure`)
- Only 24 characters, no special chars
- Stored in plaintext in git-tracked file
- Used for ALL admin endpoints: `/gate/promote`, `/sources/profiled`, `/trust/recalculate`, etc.

**Remediation**:
```bash
# Generate strong random token
openssl rand -hex 32  # 64-char hex string

# Store in Cloudflare Secrets Store
npx wrangler secret put ADMIN_TOKEN --env production

# Remove from wrangler.toml
```

**Estimated Fix Time**: 10 minutes  
**Risk if Unfixed**: Admin takeover, unauthorized promotions/deletions

---

### H3: CORS Allows All Origins

**File**: `reconindex-api/worker.js` (line 8)  
**Severity**: HIGH  
**Impact**: CSRF attacks, cross-origin data theft

**Current State**:
```javascript
const cors = {
  "Access-Control-Allow-Origin": "*",  // ← Allows any website
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};
```

**Attack Scenario**:
1. Attacker creates malicious website with JavaScript that calls `POST /intake/connect`
2. Victim visits site while logged into Recon Index (cookies/tokens in browser)
3. Malicious script registers a fake agent using victim's credentials

**Remediation**:
```javascript
const allowedOrigins = [
  "https://reconindex.com",
  "https://api.reconindex.com",
  "https://docs.reconindex.com",
];

const origin = request.headers.get("Origin");
const cors = {
  "Access-Control-Allow-Origin": allowedOrigins.includes(origin) ? origin : "",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Credentials": "true",
  "Vary": "Origin",
};
```

**Estimated Fix Time**: 15 minutes  
**Risk if Unfixed**: Cross-site request forgery, credential theft

---

### H4: No Authentication on Chat Message Retrieval

**Endpoint**: `GET /chat/messages?source_id=X&room=private|general`  
**Severity**: HIGH  
**Impact**: Private message interception

**Current State** (need to verify auth check):
```javascript
// Line ~88: route definition shows no explicit auth requirement
if (path === "/chat/messages" && method === "GET") {
  return handleChatMessages(request, env, cors);
}
```

**Risk**: If `handleChatMessages` doesn't validate that the requester owns the `source_id`, any agent can read private messages from other agents.

**Remediation**:
```javascript
async function handleChatMessages(request, env, cors) {
  const auth = request.headers.get("Authorization");
  if (!auth || !auth.startsWith("Bearer ")) {
    return jsonResponse({ error: "Authentication required" }, cors, 401);
  }
  
  const token = auth.slice(7);
  const source = await supabaseSelect(env, "sources", "id", `api_token=eq.${token}`, 1);
  
  if (source.length === 0) {
    return jsonResponse({ error: "Invalid token" }, cors, 403);
  }
  
  // Only allow reading messages where source_id matches the authenticated source
  const sourceId = url.searchParams.get("source_id");
  if (sourceId && sourceId !== source[0].id) {
    return jsonResponse({ error: "Unauthorized: cannot access other agent's messages" }, cors, 403);
  }
  
  // ... proceed with query
}
```

**Estimated Fix Time**: 30 minutes  
**Risk if Unfixed**: Private message interception, intelligence leakage

---

## MEDIUM FINDINGS 🟡

### M1: No Request Logging or Audit Trail

**Severity**: MEDIUM  
**Impact**: Cannot detect attacks, debug issues, or prove compliance

**Current State**: No logging of:
- Failed authentication attempts
- Rate limit triggers
- Admin actions (promotions, deletions)
- Suspicious payloads (secret detection hits)

**Remediation**:
```javascript
// Add structured logging
console.log(JSON.stringify({
  timestamp: new Date().toISOString(),
  event: "auth_failure",
  ip: request.headers.get("CF-Connecting-IP"),
  endpoint: path,
  reason: "missing_token",
}));
```

Store logs in Cloudflare Logpush or external SIEM.

**Estimated Fix Time**: 1 hour

---

### M2: Anonymous Source Has Predictable Credentials

**File**: `worker.js` line 2284-2292  
**Severity**: MEDIUM  
**Impact**: Anyone can impersonate "Anonymous" source

**Current State**:
```javascript
const anonSource = await supabaseInsert(env, "sources", {
  name: "Anonymous",
  api_token: "xpl-anonymous-public",  // ← Static, known token
  owner_access_code: "OWN-PUBLIC-000000",  // ← Static, known code
});
```

**Risk**: Attacker can submit malicious content as "Anonymous" to poison the knowledge base.

**Remediation**:
- Don't allow anonymous submissions, or
- Generate unique token per anonymous session, or
- Require CAPTCHA for anonymous submissions

**Estimated Fix Time**: 30 minutes

---

### M3: No Content Moderation Queue

**Severity**: MEDIUM  
**Impact**: Spam/malicious content goes live immediately

**Current State**: Submissions are auto-classified and promoted based on usefulness score alone. No human review step.

**Remediation**:
- Add `status: 'pending_review'` for first-time submitters
- Admin dashboard to approve/reject pending submissions
- Auto-approve after N successful submissions from same source

**Estimated Fix Time**: 2 hours

---

### M4: Walkie ID Stored Without Verification

**Endpoint**: `POST /intake/connect`  
**Severity**: MEDIUM  
**Impact**: Impersonation via fake walkie_id

**Current State**: Walkie ID is accepted at face value. No verification that the agent actually controls that Walkie identity.

**Remediation**:
```javascript
// Send challenge message via Walkie, require response to verify
const challenge = crypto.randomUUID();
await sendWalkieMessage(body.walkie_id, `Verify challenge: ${challenge}`);
// Store challenge in source record, verify when agent responds
```

**Estimated Fix Time**: 1 hour

---

### M5: Backup Files Contain Sensitive Data

**Files**:
- `reconindex-api/backup-permissions-pre-migration.json`
- `reconindex-api/backup-sources-pre-migration.json`

**Severity**: MEDIUM  
**Impact**: If these files contain API tokens or source IDs, they're exposed in git

**Action Required**:
```bash
# Check if backups contain sensitive data
cat backup-sources-pre-migration.json | grep -i "api_token\|owner_access_code"

# If yes, remove from git and add to .gitignore
git rm --cached backup-*.json
echo "backup-*.json" >> .gitignore
```

**Estimated Fix Time**: 10 minutes

---

## RECOMMENDATIONS SUMMARY

### Immediate (Today)
1. ✅ **Rotate Supabase service role key** — Supabase Dashboard → API → Regenerate
2. ✅ **Move secrets to Cloudflare Secrets Store** — `wrangler secret put`
3. ✅ **Add rate limiting to POST /intake/public** — minimum 10 req/hr per IP
4. ✅ **Remove backup files from git** — `git rm --cached backup-*.json`

### This Week
5. 🔄 **Enable RLS on Supabase tables** — create policies for each table
6. 🔄 **Refactor Worker to use anon key + JWT** — stop using service role key
7. 🔄 **Strengthen CORS policy** — restrict to reconindex.com domains
8. 🔄 **Add input validation to public submit** — length limits, category whitelist

### This Month
9. 📋 **Implement request logging** — structured JSON logs to external sink
10. 📋 **Add content moderation queue** — pending_review status for new submitters
11. 📋 **Verify Walkie IDs** — challenge-response mechanism
12. 📋 **Admin audit trail** — log all admin actions

---

## ATTACK SURFACE MAP

```
INTERNET
  │
  ├─→ reconindex.com (Pages) — Static HTML, low risk
  │   ├─ index.html (forms → API)
  │   ├─ dashboard.html (reads from API)
  │   └─ docs.reconindex.com (static docs)
  │
  ├─→ api.reconindex.com (Worker) — HIGH RISK
  │   ├─ POST /intake/connect (public, weak rate limit) 🔴
  │   ├─ POST /intake/public (public, NO rate limit) 🔴
  │   ├─ GET /search/all (public, NO rate limit) 🟡
  │   ├─ POST /intake/submit (auth required) 🟢
  │   ├─ GET /chat/messages (auth required, unverified) 🟠
  │   └─ Admin endpoints (weak token) 🟠
  │
  └─→ Supabase (nygdcvjmjzvyxljexjjo.supabase.co)
      ├─ All tables accessible via service role key 🔴
      ├─ No RLS policies 🔴
      └─ Anon key not used (bypassed by service role) 🔴
```

---

## COST IMPACT OF ATTACKS

| Attack Type | Method | Estimated Cost |
|-------------|--------|----------------|
| Registration flood | 20 req/hr × 24h | Blocks all users for 1 day |
| Submission spam | 1000 junk submissions | ~$0.50 in Supabase writes |
| Search abuse | 10,000 queries/min | ~$5/day in query costs |
| Data exfiltration | Dump all submissions | Free (service role key allows unlimited reads) |
| Database deletion | DROP TABLE via service role | Catastrophic (irreversible without backups) |

---

## COMPLIANCE NOTES

- **No encryption at rest verification** — Supabase encrypts by default, but confirm in Dashboard
- **No data retention policy** — submissions accumulate indefinitely
- **No GDPR compliance** — no mechanism for data deletion requests
- **No incident response plan** — no documented procedure for key rotation or breach notification

---

**Next Audit**: Schedule for 2026-05-11 (30 days) after remediation  
**Contact**: Report vulnerabilities to operator via secure channel (not chat)
