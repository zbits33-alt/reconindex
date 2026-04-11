#!/bin/bash
# ═══════════════════════════════════════════════════════
# EXPORT CURRENT SESSION TO memory/
# Saves conversation transcript for persistent storage
# ═══════════════════════════════════════════════════════

TIMESTAMP=$(date -u +'%Y-%m-%d_%H%M')
OUTPUT="/home/agent/workspace/memory/session_${TIMESTAMP}.md"

echo "Exporting current session to $OUTPUT..."

# Use OpenClaw CLI to get session history
# This requires the openclaw binary to be available
if command -v openclaw &> /dev/null; then
    # Get current session key
    SESSION_KEY=$(openclaw sessions list --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data and len(data) > 0:
    print(data[0].get('key', ''))
" 2>/dev/null)
    
    if [ -n "$SESSION_KEY" ]; then
        echo "Session key: $SESSION_KEY"
        
        # Export full history
        openclaw sessions history --session "$SESSION_KEY" --limit 100 --include-tools 2>/dev/null > "$OUTPUT"
        
        if [ $? -eq 0 ] && [ -s "$OUTPUT" ]; then
            echo "✓ Session exported successfully ($(wc -l < "$OUTPUT") lines)"
        else
            echo "✗ Export failed or empty"
            rm -f "$OUTPUT"
        fi
    else
        echo "✗ Could not determine session key"
    fi
else
    echo "✗ openclaw CLI not found"
fi
