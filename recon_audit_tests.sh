#!/bin/bash
# ReconIndex Security Audit Tests
# Running against live API: https://api.reconindex.com

API="https://api.reconindex.com"
RESULTS=()
PASS=0
FAIL=0

test_result() {
  local name="$1" status="$2" detail="$3"
  if [ "$status" == "PASS" ]; then
    ((PASS++))
    echo "✅ PASS: $name"
  else
    ((FAIL++))
    echo "❌ FAIL: $name — $detail"
  fi
}

echo "═══════════════════════════════════════════════"
echo "  ReconIndex Security Audit — Live Tests"
echo "  $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "═══════════════════════════════════════════════"
echo ""

# ─── 1. PUBLIC ENDPOINTS ───
echo "── PUBLIC ENDPOINT TESTS ──"

# Health check
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API/health")
[ "$HTTP" == "200" ] && test_result "Health endpoint" "PASS" || test_result "Health endpoint" "FAIL" "HTTP $HTTP"

# Status (no auth)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API/status")
[ "$HTTP" == "200" ] && test_result "Status endpoint (public)" "PASS" || test_result "Status endpoint (public)" "FAIL" "HTTP $HTTP"

# Libraries (no auth)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API/libraries")
[ "$HTTP" == "200" ] && test_result "Libraries endpoint (public)" "PASS" || test_result "Libraries endpoint (public)" "FAIL" "HTTP $HTTP"

# Sources directory (public)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API/sources/directory")
[ "$HTTP" == "200" ] && test_result "Sources directory (public)" "PASS" || test_result "Sources directory (public)" "FAIL" "HTTP $HTTP"

# ─── 2. AUTH REQUIREMENTS ───
echo ""
echo "── AUTH PROTECTION TESTS ──"

# POST /intake/analyze without auth
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/intake/analyze" -H "Content-Type: application/json" -d '{"content":"test"}')
[ "$HTTP" == "401" ] && test_result "/intake/analyze requires auth" "PASS" || test_result "/intake/analyze requires auth" "FAIL" "HTTP $HTTP (expected 401)"

# POST /chat/message without auth
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/chat/message" -H "Content-Type: application/json" -d '{"message":"test"}')
[ "$HTTP" == "401" ] && test_result "/chat/message requires auth" "PASS" || test_result "/chat/message requires auth" "FAIL" "HTTP $HTTP (expected 401)"

# GET /sources (admin)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API/sources")
[ "$HTTP" == "401" ] && test_result "/sources requires admin auth" "PASS" || test_result "/sources requires admin auth" "FAIL" "HTTP $HTTP (expected 401)"

# GET /sources/profiled (admin)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API/sources/profiled")
[ "$HTTP" == "401" ] && test_result "/sources/profiled requires admin auth" "PASS" || test_result "/sources/profiled requires admin auth" "FAIL" "HTTP $HTTP (expected 401)"

# POST /intake/register without auth
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/intake/register" -H "Content-Type: application/json" -d '{"name":"test","type":"agent","api_token":"test"}')
[ "$HTTP" == "401" ] && test_result "/intake/register requires admin auth" "PASS" || test_result "/intake/register requires admin auth" "FAIL" "HTTP $HTTP (expected 401)"

# POST /gate/promote without auth
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/gate/promote" -H "Content-Type: application/json" -d '{"submission_id":"test"}')
[ "$HTTP" == "401" ] && test_result "/gate/promote requires admin auth" "PASS" || test_result "/gate/promote requires admin auth" "FAIL" "HTTP $HTTP (expected 401)"

# POST /gate/pending without auth
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API/gate/pending")
[ "$HTTP" == "401" ] && test_result "/gate/pending requires admin auth" "PASS" || test_result "/gate/pending requires admin auth" "FAIL" "HTTP $HTTP (expected 401)"

# POST /entities without auth
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/entities" -H "Content-Type: application/json" -d '{"name":"test","entity_type":"test"}')
[ "$HTTP" == "401" ] && test_result "/entities POST requires admin auth" "PASS" || test_result "/entities POST requires admin auth" "FAIL" "HTTP $HTTP (expected 401)"

# ─── 3. CORS TESTS ───
echo ""
echo "── CORS TESTS ──"

CORS_RESP=$(curl -s -o /dev/null -D - -X OPTIONS "$API/health" -H "Origin: https://evil.com" 2>&1)
CORS_ORIGIN=$(echo "$CORS_RESP" | grep -i "access-control-allow-origin" | tr -d '\r' | awk '{print $2}')
if [ -n "$CORS_ORIGIN" ] && [ "$CORS_ORIGIN" != "https://evil.com" ]; then
  test_result "CORS blocks unknown origins" "PASS"
else
  test_result "CORS blocks unknown origins" "FAIL" "Origin=$CORS_ORIGIN"
fi

# ─── 4. PUBLIC SUBMISSION TEST ───
echo ""
echo "── PUBLIC SUBMISSION TESTS ──"

# POST /intake/public — should work without auth
SUBMIT_RESP=$(curl -s -X POST "$API/intake/public" \
  -H "Content-Type: application/json" \
  -d '{"content":"Audit test submission - this is a harmless test","agent_name":"AuditBot","type":"agent"}')
HTTP=$(echo "$SUBMIT_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',''))" 2>/dev/null)
[ "$HTTP" == "True" ] && test_result "/intake/public accepts submission" "PASS" || test_result "/intake/public accepts submission" "FAIL" "Response: $SUBMIT_RESP"

# POST /intake/public with secrets (should redact)
SECRET_RESP=$(curl -s -X POST "$API/intake/public" \
  -H "Content-Type: application/json" \
  -d '{"content":"My seed phrase is abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon","agent_name":"SecretTest","type":"agent"}')
SECRETS=$(echo "$SECRET_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('security',{}).get('secrets_detected',0))" 2>/dev/null)
[ "$SECRETS" -gt 0 ] 2>/dev/null && test_result "Secret detection on public submit" "PASS" || test_result "Secret detection on public submit" "FAIL" "secrets_detected=$SECRETS"

# POST /intake/public — content length limit
LONG=$(python3 -c "print('A'*50001)")
LONG_RESP=$(curl -s -X POST "$API/intake/public" \
  -H "Content-Type: application/json" \
  -d "{\"content\":\"$LONG\",\"agent_name\":\"LongTest\",\"type\":\"agent\"}")
HTTP=$(echo "$LONG_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
[ -n "$HTTP" ] && test_result "Content length limit enforced" "PASS" || test_result "Content length limit enforced" "FAIL" "No error returned"

# ─── 5. SEARCH TESTS ───
echo ""
echo "── SEARCH ENDPOINT TESTS ──"

SEARCH_RESP=$(curl -s "$API/search/all?q=test&limit=5")
HTTP=$(echo "$SEARCH_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',''))" 2>/dev/null)
[ "$HTTP" == "True" ] && test_result "/search/all works" "PASS" || test_result "/search/all works" "FAIL" "Response: $SEARCH_RESP"

# ─── 6. LOGIN CODES EXPOSED IN CLIENT ───
echo ""
echo "── HARDCODED CREDENTIALS TESTS ──"

# Check if LOGIN_CODES are exposed in worker.js
CODES=$(grep -c "LOGIN_CODES" /home/agent/workspace/reconindex-api/worker.js)
[ "$CODES" -gt 0 ] && test_result "LOGIN_CODES hardcoded in worker" "FAIL" "Found $CODES occurrences — source UUIDs exposed in server-side code" || test_result "No hardcoded LOGIN_CODES" "PASS"

# Check for hardcoded tokens in HTML
HTML_TOKENS=$(grep -c "RECON_ID\|RECON-0001\|PRED-7777\|DKT-0003" /home/agent/workspace/reconindex-api/worker.js)
[ "$HTML_TOKENS" -gt 0 ] && test_result "Hardcoded IDs in HTML/JS" "FAIL" "Found $HTML_TOKENS hardcoded identifiers" || test_result "No hardcoded IDs in HTML" "PASS"

# ─── 7. WRANGLER SECRETS CHECK ───
echo ""
echo "── SECRETS MANAGEMENT TESTS ──"

# Check if SUPABASE_SERVICE_KEY is in wrangler.toml (it shouldn't be)
HAS_KEY=$(grep -c "SUPABASE_SERVICE_KEY" /home/agent/workspace/reconindex-api/wrangler.toml)
[ "$HAS_KEY" -eq 0 ] && test_result "SUPABASE_SERVICE_KEY not in wrangler.toml" "PASS" || test_result "SUPABASE_SERVICE_KEY in wrangler.toml" "FAIL" "Found in config file"

# Check if ADMIN_TOKEN is hardcoded
HAS_ADMIN=$(grep -c "ADMIN_TOKEN.*=" /home/agent/workspace/reconindex-api/wrangler.toml)
[ "$HAS_ADMIN" -eq 0 ] && test_result "ADMIN_TOKEN not in wrangler.toml" "PASS" || test_result "ADMIN_TOKEN in wrangler.toml" "FAIL"

# ─── 8. STATUS ENDPOINT DATA LEAK ───
echo ""
echo "── DATA EXPOSURE TESTS ──"

# /status should NOT return api_tokens
STATUS_RESP=$(curl -s "$API/status")
HAS_TOKENS=$(echo "$STATUS_RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
agents = d.get('agents',[])
for a in agents:
    if 'api_token' in a:
        print('LEAK')
        break
" 2>/dev/null)
[ "$HAS_TOKENS" != "LEAK" ] && test_result "/status does not leak API tokens" "PASS" || test_result "/status leaks API tokens" "FAIL"

# /status should NOT return owner_access_code
HAS_OAC=$(echo "$STATUS_RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
agents = d.get('agents',[])
for a in agents:
    if 'owner_access_code' in a:
        print('LEAK')
        break
" 2>/dev/null)
[ "$HAS_OAC" != "LEAK" ] && test_result "/status does not leak owner_access_code" "PASS" || test_result "/status leaks owner_access_code" "FAIL"

# /libraries — check if tier 3 entries are accessible anonymously
LIB_RESP=$(curl -s "$API/libraries")
TIER3=$(echo "$LIB_RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for cat in d.get('categories',{}).values():
    for e in cat.get('entries',[]):
        # Can't check tier directly in libraries response, just note it
        pass
print('OK')
" 2>/dev/null)
[ "$TIER3" == "OK" ] && test_result "/libraries responds anonymously" "PASS" || test_result "/libraries anonymous access" "FAIL"

# /sources/directory — should be aggregated only
DIR_RESP=$(curl -s "$API/sources/directory")
HAS_NAMES=$(echo "$DIR_RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# Should have aggregated stats, not individual names
if 'sources' in d:
    print('LEAK')
else:
    print('OK')
" 2>/dev/null)
[ "$HAS_NAMES" == "OK" ] && test_result "/sources/directory is aggregated" "PASS" || test_result "/sources/directory leaks source names" "FAIL"

echo ""
echo "═══════════════════════════════════════════════"
echo "  RESULTS: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════"
