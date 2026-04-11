#!/bin/bash
# Wrapper for Recon Collections Sync
# Loads Supabase credentials from secrets.md before running the sync script.

set -e

SECRETS_FILE="/home/agent/workspace/memory/secrets.md"
SYNC_SCRIPT="/home/agent/workspace/reconindex-api/scripts/sync-collections.py"

if [ ! -f "$SECRETS_FILE" ]; then
    echo "[sync-wrapper] ERROR: secrets.md not found at $SECRETS_FILE"
    exit 1
fi

export SUPABASE_SERVICE_KEY=$(grep 'supabase_service_role=' "$SECRETS_FILE" | cut -d= -f2)

if [ -z "$SUPABASE_SERVICE_KEY" ]; then
    echo "[sync-wrapper] ERROR: Could not extract supabase_service_role from secrets.md"
    exit 1
fi

echo "[sync-wrapper] Credentials loaded, running sync..."
python3 "$SYNC_SCRIPT" "$@"
