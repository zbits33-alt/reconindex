#!/bin/bash
# Recon Index Security Remediation Script
# Run this to fix CRITICAL and HIGH severity findings
# Date: 2026-04-11

set -e

echo "=== Recon Index Security Remediation ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd /home/agent/workspace

# ─── STEP 1: Remove backup files from git ───
echo -e "${YELLOW}[1/5] Removing backup files from git...${NC}"
if git ls-files | grep -q "backup-.*\.json"; then
    git rm --cached reconindex-api/backup-*.json 2>/dev/null || true
    echo "backup-*.json" >> .gitignore
    echo -e "${GREEN}✓ Backup files removed from git${NC}"
else
    echo -e "${GREEN}✓ No backup files in git${NC}"
fi

# ─── STEP 2: Create wrangler.toml template (without secrets) ───
echo -e "${YELLOW}[2/5] Creating wrangler.toml template...${NC}"
cat > reconindex-api/wrangler.toml.example << 'EOF'
name = "recon-intake-api"
main = "worker.js"
compatibility_date = "2026-04-09"

# DO NOT commit this file with real values!
# Use `wrangler secret put` to set these:
# - SUPABASE_URL
# - SUPABASE_SERVICE_KEY
# - ADMIN_TOKEN

[[routes]]
pattern = "api.reconindex.com/*"
zone_name = "reconindex.com"
custom_domain = false
EOF

# Check if wrangler.toml is tracked
if git ls-files | grep -q "reconindex-api/wrangler.toml"; then
    echo -e "${RED}⚠ WARNING: wrangler.toml is tracked in git!${NC}"
    echo "   After setting secrets via 'wrangler secret put', run:"
    echo "   git rm --cached reconindex-api/wrangler.toml"
    echo "   echo 'wrangler.toml' >> .gitignore"
fi

# ─── STEP 3: Add rate limiting helper to Worker ───
echo -e "${YELLOW}[3/5] Checking rate limiting implementation...${NC}"
if grep -q "checkRateLimit" reconindex-api/worker.js; then
    echo -e "${GREEN}✓ Rate limiting already implemented${NC}"
else
    echo -e "${RED}⚠ Rate limiting NOT implemented${NC}"
    echo "   See SECURITY_AUDIT_RECON_INDEX_2026-04-11.md section C2"
    echo "   Manual fix required: Add KV-based rate limiting to Worker"
fi

# ─── STEP 4: Check CORS configuration ───
echo -e "${YELLOW}[4/5] Checking CORS configuration...${NC}"
if grep -q '"Access-Control-Allow-Origin": "\*"' reconindex-api/worker.js; then
    echo -e "${RED}⚠ CORS allows all origins (*)${NC}"
    echo "   See SECURITY_AUDIT_RECON_INDEX_2026-04-11.md section H3"
    echo "   Manual fix required: Restrict to reconindex.com domains"
else
    echo -e "${GREEN}✓ CORS is restricted${NC}"
fi

# ─── STEP 5: Verify RLS status ───
echo -e "${YELLOW}[5/5] Checking Supabase RLS status...${NC}"
SUPABASE_URL="https://nygdcvjmjzvyxljexjjo.supabase.co"
SUPABASE_KEY=$(grep supabase_service_role memory/secrets.md | cut -d'=' -f2)

if [ -z "$SUPABASE_KEY" ]; then
    echo -e "${RED}✗ Supabase key not found in memory/secrets.md${NC}"
    exit 1
fi

# Check if RLS is enabled on sources table
RLS_STATUS=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/rpc/check_rls_status" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" \
  -H "Content-Type: application/json" 2>&1 || echo "rpc_not_found")

if [[ "$RLS_STATUS" == *"rpc_not_found"* ]] || [[ "$RLS_STATUS" == *"error"* ]]; then
    echo -e "${RED}⚠ Cannot verify RLS status via API${NC}"
    echo "   Manual check required:"
    echo "   1. Go to https://app.supabase.com/project/nygdcvjmjzvyxljexjjo"
    echo "   2. Navigate to Authentication → Policies"
    echo "   3. Verify RLS is enabled on: sources, submissions, permissions, knowledge_units, patterns"
    echo ""
    echo "   Or run this SQL in Supabase SQL Editor:"
    echo "   SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';"
else
    echo -e "${GREEN}✓ RLS status check completed${NC}"
fi

echo ""
echo "=== Summary ==="
echo ""
echo -e "${RED}CRITICAL actions required:${NC}"
echo "1. Rotate Supabase service role key (Supabase Dashboard → API → Regenerate)"
echo "2. Set secrets via Cloudflare: wrangler secret put SUPABASE_SERVICE_KEY"
echo "3. Set secrets via Cloudflare: wrangler secret put ADMIN_TOKEN"
echo "4. Remove wrangler.toml from git after setting secrets"
echo ""
echo -e "${YELLOW}HIGH priority actions:${NC}"
echo "5. Add rate limiting to POST /intake/public endpoint"
echo "6. Enable RLS on all Supabase tables"
echo "7. Restrict CORS to reconindex.com domains"
echo "8. Add input validation to public submit endpoint"
echo ""
echo "Full details: SECURITY_AUDIT_RECON_INDEX_2026-04-11.md"
echo ""
echo -e "${GREEN}Script complete.${NC}"
