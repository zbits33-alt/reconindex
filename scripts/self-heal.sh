#!/bin/bash
# ═══════════════════════════════════════════════════════
# RECON SELF-HEAL — System health monitor & auto-recovery
# Runs every 2 min via system crontab (NOT agent cron = zero RLUSD cost)
# Checks: API, Site, Supabase, Walkie, Market Data
# Auto-recovers: Walkie daemon restart + channel reconnect
# Writes live status JSON for site polling
# ═══════════════════════════════════════════════════════

LOG="/home/agent/workspace/logs/self-heal.log"
STATUS="/home/agent/workspace/reconindex-site/api/status.json"
mkdir -p "$(dirname "$LOG")" "$(dirname "$STATUS")"

# Trim log if too large
if [ -f "$LOG" ] && [ $(wc -l < "$LOG") -gt 2000 ]; then
  tail -500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

log() { echo "[$(date -u '+%H:%M:%S')] $1" >> "$LOG"; }
log "━━━ self-heal cycle ━━━"

# ── 1. API Worker ──
API_RESP=$(curl -s -m 5 https://api.reconindex.com/health 2>/dev/null)
if echo "$API_RESP" | grep -q '"ok"'; then
  log "✅ API healthy"; API_OK=true
else
  log "❌ API DOWN"; API_OK=false
fi

# ── 2. Site ──
SITE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 https://reconindex.com/ 2>/dev/null)
if [ "$SITE_CODE" = "200" ]; then
  log "✅ Site healthy"; SITE_OK=true
else
  log "❌ Site DOWN ($SITE_CODE)"; SITE_OK=false
fi

# ── 3. Supabase ──
SB_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 \
  "https://nygdcvjmjzvyxljexjjo.supabase.co/rest/v1/sources?select=id&limit=1" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55Z2Rjdmptanp2eXhsamV4ampvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MDkzMjEsImV4cCI6MjA5MTI4NTMyMX0.sc2ZDc0r_l6O6CEfhmxO_c0BlG40DFB3U16HnQ8lt7U" 2>/dev/null)
if [ "$SB_CODE" = "200" ]; then
  log "✅ Supabase healthy"; SB_OK=true
else
  log "❌ Supabase DOWN ($SB_CODE)"; SB_OK=false
fi

# ── 4. Walkie Daemon ──
export PATH="$HOME/.npm-global/bin:$PATH"
WALKIE_OK=false
WALKIE_PEERS=0
if walkie status 2>/dev/null | grep -q "Daemon ID"; then
  # Count channels with buffered or stored messages (sign of activity)
  WALKIE_ACTIVE=$(walkie status 2>/dev/null | grep -cP '\[persist: [1-9]')
  WALKIE_PEERS=$(walkie status 2>/dev/null | grep -oP '\d+(?= peer)' | paste -sd+ | bc 2>/dev/null || echo "0")
  if [ "$WALKIE_ACTIVE" -gt 0 ] 2>/dev/null; then
    WALKIE_OK=true; log "✅ Walkie: $WALKIE_PEERS peers, $WALKIE_ACTIVE active channels"
  else
    log "⚠️ Walkie running but no active channels — reconnecting"
    walkie connect xc-recon-eaf6 --persist 2>/dev/null
    walkie connect predator-collab --persist 2>/dev/null
    sleep 3
    WALKIE_ACTIVE=$(walkie status 2>/dev/null | grep -cP '\[persist: [1-9]')
    WALKIE_PEERS=$(walkie status 2>/dev/null | grep -oP '\d+(?= peer)' | paste -sd+ | bc 2>/dev/null || echo "0")
    [ "$WALKIE_ACTIVE" -gt 0 ] 2>/dev/null && { WALKIE_OK=true; log "✅ Walkie reconnected: $WALKIE_ACTIVE channels"; } || log "❌ Walkie reconnect failed"
  fi
else
  log "❌ Walkie DOWN — restarting"
  walkie daemon start 2>/dev/null; sleep 3
  walkie connect xc-recon-eaf6 --persist 2>/dev/null
  walkie connect predator-collab --persist 2>/dev/null; sleep 2
  walkie status 2>/dev/null | grep -q "Daemon ID" && { WALKIE_OK=true; log "✅ Walkie restarted"; } || log "❌ Walkie restart failed"
fi

# ── 5. Market Data ──
MARKET_OK=false
if [ -f /home/agent/workspace/state/market/briefing.md ]; then
  MTIME=$(stat -c %Y /home/agent/workspace/state/market/briefing.md 2>/dev/null || echo 0)
  AGE=$(( $(date +%s) - MTIME ))
  if [ "$AGE" -lt 600 ]; then MARKET_OK=true; log "✅ Market fresh (${AGE}s)"
  else log "⚠️ Market stale (${AGE}s)"; fi
else log "❌ Market missing"; fi

# ── 6. Collect stats ──
SK="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55Z2Rjdmptanp2eXhsamV4ampvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTcwOTMyMSwiZXhwIjoyMDkxMjg1MzIxfQ.sPHZ0c7yxquUQkHzXFSyBlCSqm4p_j4Um8mIaLLVtkQ"
SU="https://nygdcvjmjzvyxljexjjo.supabase.co"

count_rows() {
  local h; h=$(curl -sI -m 5 "$SU/rest/v1/$1" \
    -H "apikey: $SK" -H "Authorization: Bearer $SK" \
    -H "Prefer: count=exact" 2>/dev/null)
  echo "$h" | tr -d '\r' | grep -i content-range | sed 's|.*/||' | tr -d '[:space:]'
}

N_AGENTS=$(count_rows "sources")
N_PRIV=$(count_rows "chat_messages")
N_GEN=$(count_rows "general_chat_messages")
N_SESS=$(count_rows "agent_sessions")
N_SUBS=$(count_rows "submissions")
N_KU=$(count_rows "knowledge_units")
N_PAT=$(count_rows "patterns")

# Fetch data blobs
AGENTS_JSON=$(curl -s -m 5 "$SU/rest/v1/sources?select=id,name,type,owner,active,created_at&order=created_at.asc" \
  -H "apikey: $SK" -H "Authorization: Bearer $SK" 2>/dev/null || echo "[]")
MSG_JSON=$(curl -s -m 5 "$SU/rest/v1/general_chat_messages?select=id,sender,sender_id,message,created_at&order=created_at.desc&limit=50" \
  -H "apikey: $SK" -H "Authorization: Bearer $SK" 2>/dev/null || echo "[]")
PAT_JSON=$(curl -s -m 5 "$SU/rest/v1/patterns?select=id,pattern_type,title,description,occurrence_count,last_seen,tags&order=occurrence_count.desc" \
  -H "apikey: $SK" -H "Authorization: Bearer $SK" 2>/dev/null || echo "[]")
SUB_JSON=$(curl -s -m 5 "$SU/rest/v1/submissions?select=id,source_id,category,summary,submitted_at&order=submitted_at.desc&limit=20" \
  -H "apikey: $SK" -H "Authorization: Bearer $SK" 2>/dev/null || echo "[]")

# Determine overall health
HEALTHY=true
ISSUES=""
$API_OK || { HEALTHY=false; ISSUES="${ISSUES}api_down,"; }
$SITE_OK || { HEALTHY=false; ISSUES="${ISSUES}site_down,"; }
$SB_OK || { HEALTHY=false; ISSUES="${ISSUES}supabase_down,"; }
$WALKIE_OK || { HEALTHY=false; ISSUES="${ISSUES}walkie_down,"; }
$MARKET_OK || { HEALTHY=false; ISSUES="${ISSUES}market_stale,"; }

# Write status JSON (convert bash bools to Python)
TS=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
python3 - "$TS" "$HEALTHY" "$API_OK" "$SITE_OK" "$SB_OK" "$WALKIE_OK" "$MARKET_OK" \
  "$WALKIE_PEERS" "$N_AGENTS" "$N_PRIV" "$N_GEN" "$N_SESS" "$N_SUBS" "$N_KU" "$N_PAT" \
  "$ISSUES" "$AGENTS_JSON" "$MSG_JSON" "$PAT_JSON" "$SUB_JSON" "$STATUS" << 'PYEOF' >> "$LOG" 2>&1
import json, sys
ts, healthy, api_ok, site_ok, sb_ok, walkie_ok, market_ok = sys.argv[1:8]
peers, agents, priv, gen, sess, subs, ku, pat = [int(x) for x in sys.argv[8:16]]
issues_str, agents_json, msg_json, pat_json, sub_json, status_file = sys.argv[16:22]

issues = issues_str.strip(',').split(',') if issues_str.strip(',') else []
def pb(v): return v.lower() == 'true'

data = {
    'ts': ts, 'healthy': pb(healthy), 'issues': issues,
    'services': {
        'api': pb(api_ok), 'site': pb(site_ok), 'supabase': pb(sb_ok),
        'walkie': pb(walkie_ok), 'market': pb(market_ok),
    },
    'walkie_peers': peers,
    'stats': {
        'agents': agents, 'private_messages': priv, 'general_messages': gen,
        'sessions': sess, 'submissions': subs, 'knowledge_units': ku, 'patterns': pat,
    },
    'agents': json.loads(agents_json),
    'recent_messages': json.loads(msg_json),
    'patterns': json.loads(pat_json),
    'recent_submissions': json.loads(sub_json),
}
with open(status_file, 'w') as f:
    json.dump(data, f, indent=2)
print('Status written')
PYEOF

log "Stats: ${N_AGENTS:-0} agents · ${N_GEN:-0} msgs · ${N_SESS:-0} sessions · ${N_PAT:-0} patterns"
$HEALTHY && log "✅ ALL HEALTHY" || log "⚠️ ISSUES: ${ISSUES}"
