#!/bin/bash
# Self-healing service checker — runs every 3 min via cron
# Restarts anything that's dead. No loops, no hangs.
# Logs to /home/agent/workspace/state/services.log

set -euo pipefail

export PATH="$HOME/.npm-global/bin:$PATH"
LOGFILE="/home/agent/workspace/state/services.log"
TUNNEL_URL_FILE="/home/agent/workspace/state/tunnel-url.txt"
DASHBOARD_DIR="/home/agent/workspace/dashboard"
DASHBOARD_PORT=3457
RECON_DIR="/home/agent/workspace"

mkdir -p "$(dirname "$LOGFILE")"

log() {
  echo "[$(date -Iseconds)] $*" >> "$LOGFILE"
}

# Keep log under 50KB
if [ "$(wc -c < "$LOGFILE" 2>/dev/null || echo 0)" -gt 50000 ]; then
  tail -c 20000 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
  log "Log rotated"
fi

# ── 1. Walkie daemon ──────────────────────────────────────
# The daemon should always be running. Check and restart if needed.
if ! pgrep -f "walkie" > /dev/null 2>&1; then
  log "⚠ Walkie daemon not found — walkie commands will fail"
  # Daemon auto-starts on first walkie command, so just trigger it
  WALKIE_ID=Recon walkie status > /dev/null 2>&1 || true
  log "✓ Walkie daemon re-triggered"
fi

# ── 2. Dashboard HTTP server ──────────────────────────────
if ! ss -tlnp 2>/dev/null | grep -q ":$DASHBOARD_PORT" && \
   ! lsof -i :$DASHBOARD_PORT > /dev/null 2>&1; then
  log "⚠ Dashboard server on port $DASHBOARD_PORT is DOWN — restarting"
  # Kill any zombie processes on that port
  fuser -k $DASHBOARD_PORT/tcp 2>/dev/null || true
  sleep 1
  # Start fresh in background
  cd "$DASHBOARD_DIR"
  nohup npx -y serve -l $DASHBOARD_PORT . > /dev/null 2>&1 &
  log "✓ Dashboard server restarted (PID $!)"
else
  log "✓ Dashboard server OK on :$DASHBOARD_PORT"
fi

# ── 3. Cloudflare tunnel ──────────────────────────────────
# Quick tunnels die unpredictably. Check if current tunnel is alive.
CURRENT_TUNNEL=""
if [ -f "$TUNNEL_URL_FILE" ]; then
  CURRENT_TUNNEL=$(cat "$TUNNEL_URL_FILE" 2>/dev/null || echo "")
fi

TUNNEL_ALIVE=false
if [ -n "$CURRENT_TUNNEL" ]; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$CURRENT_TUNNEL" 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    TUNNEL_ALIVE=true
  fi
fi

if [ "$TUNNEL_ALIVE" = false ]; then
  log "⚠ Tunnel is DOWN ($CURRENT_TUNNEL → HTTP $HTTP_CODE) — restarting"
  # Kill old tunnel processes
  pkill -f "cloudflared tunnel" 2>/dev/null || true
  sleep 2
  # Start new tunnel in background
  nohup cloudflared tunnel --url http://localhost:$DASHBOARD_PORT > /tmp/cloudflared-recon.log 2>&1 &
  TUNNEL_PID=$!
  log "✓ Cloudflare tunnel restarting (PID $TUNNEL_PID)"
  
  # Wait for new URL (up to 15 seconds)
  for i in $(seq 1 15); do
    NEW_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/cloudflared-recon.log 2>/dev/null | tail -1)
    if [ -n "$NEW_URL" ]; then
      echo "$NEW_URL" > "$TUNNEL_URL_FILE"
      log "✓ New tunnel URL: $NEW_URL"
      # Update dashboard with new URL
      if [ -f "$DASHBOARD_DIR/index.html" ]; then
        sed -i "s|https://[a-z0-9-]*\.trycloudflare\.com|$NEW_URL|g" "$DASHBOARD_DIR/index.html" 2>/dev/null || true
        sed -i "s|https://[a-z0-9-]*\.trycloudflare\.com|$NEW_URL|g" "$DASHBOARD_DIR/walkie-dashboard.html" 2>/dev/null || true
      fi
      break
    fi
    sleep 1
  done
  
  if [ ! -s "$TUNNEL_URL_FILE" ]; then
    log "✗ Failed to get new tunnel URL after 15s"
  fi
else
  log "✓ Tunnel OK: $CURRENT_TUNNEL"
fi

# ── 4. Regenerate dashboard ───────────────────────────────
node "$RECON_DIR/scripts/gen-walkie-dashboard.js" 2>&1 | while IFS= read -r line; do
  log "  dashboard: $line"
done

# ── 5. Walkie channel status check ────────────────────────
CHANNELS=$(WALKIE_ID=Recon walkie status 2>&1 || echo "walkie failed")
ACTIVE_CHANNELS=$(echo "$CHANNELS" | grep -c "stored]" || echo "0")
log "✓ Walkie channels: $ACTIVE_CHANNELS channels with stored messages"

log "── Health check complete ──"
