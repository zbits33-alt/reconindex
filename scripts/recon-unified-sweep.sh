#!/bin/bash
# Recon Unified Sweep: Self-Heal + Libraries Sync
# Runs every 12 hours to maintain system health and data consistency.

echo "🔄 Starting Recon Unified Sweep..."

# 1. Self-Heal Check
echo "🩺 Running self-heal checks..."
bash /home/agent/workspace/scripts/self-heal.sh

# 2. Libraries Sync
echo "📚 Syncing libraries..."
bash /home/agent/workspace/scripts/sync-libraries.sh

echo "✅ Recon Unified Sweep complete."
