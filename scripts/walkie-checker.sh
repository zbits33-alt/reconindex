#!/bin/bash
# Walkie message checker — reads buffered messages and outputs them
# Called by cron job. Outputs raw messages for agent to process.
export PATH="$HOME/.npm-global/bin:$PATH"

LOG="/home/agent/workspace/logs/walkie-check.log"
mkdir -p "$(dirname "$LOG")"

echo "[$(date -u '+%H:%M:%S')] ━━━ walkie check ━━━" >> "$LOG"

# Check each channel for new buffered messages
for channel in xc-recon-eaf6 predator-collab recon-chat recon-general; do
  msgs=$(walkie read "$channel" 2>/dev/null)
  if [ -n "$msgs" ]; then
    msg_count=$(echo "$msgs" | grep -c '\[')
    echo "[$(date -u '+%H:%M:%S')] Channel $channel: $msg_count messages" >> "$LOG"
    echo "=== CHANNEL: $channel ($msg_count messages) ==="
    echo "$msgs"
  fi
done

echo "[$(date -u '+%H:%M:%S')] Check complete" >> "$LOG"
