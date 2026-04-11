#!/bin/bash
# ═══════════════════════════════════════════════════════
# CHAT INTELLIGENCE SCANNER
# Scans recent agent chats for knowledge-worthy content
# Runs via system crontab — zero agent token cost
# ═══════════════════════════════════════════════════════

LOG="/home/agent/workspace/logs/chat-scanner.log"
mkdir -p /home/agent/workspace/logs

log() { echo "[$(date -u +'%H:%M:%S')] [CHAT-SCAN] $1" >> "$LOG"; }
log "Chat intelligence scan started"

python3 << 'PYEOF'
import requests, json, os, hashlib
from datetime import datetime, timedelta, timezone

# Config
SUPABASE_URL = "https://nygdcvjmjzvyxljexjjo.supabase.co"
API_BASE = "https://api.reconindex.com"
SCAN_WINDOW_MINUTES = 60  # Only scan messages from last N minutes
MIN_USEFULNESS = 7  # Minimum score to create knowledge unit

# Read service key
with open("/home/agent/workspace/memory/secrets.md") as f:
    for line in f:
        if line.startswith("supabase_service_role="):
            SERVICE_KEY = line.strip().split("=", 1)[1]
            break

headers = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
}

def get_recent_messages():
    """Fetch chat messages from last SCAN_WINDOW_MINUTES"""
    cutoff = (datetime.now(timezone.utc) - timedelta(minutes=SCAN_WINDOW_MINUTES)).isoformat()
    
    # Query both general and private chat tables
    all_messages = []
    
    # General chat messages
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/general_chat_messages?select=*&created_at=gte.{cutoff}&order=created_at.desc&limit=50",
        headers=headers
    )
    if r.status_code == 200:
        all_messages.extend(r.json())
    
    # Private chat messages (agent-to-Recon)
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/chat_messages?select=*&created_at=gte.{cutoff}&order=created_at.desc&limit=50",
        headers=headers
    )
    if r.status_code == 200:
        all_messages.extend(r.json())
    
    return all_messages

def analyze_message(msg_text, sender_name):
    """Send message to intake/analyze for classification"""
    payload = {
        "content": msg_text,
        "source_name": sender_name or "unknown",
        "source_type": "chat_scan",
    }
    
    r = requests.post(
        f"{API_BASE}/intake/analyze",
        headers={"Content-Type": "application/json"},
        json=payload
    )
    
    if r.status_code == 200:
        return r.json()
    return None

def create_knowledge_unit(analysis, original_msg):
    """Create a knowledge unit from analyzed chat content"""
    if not analysis or analysis.get("usefulness_score", 0) < MIN_USEFULNESS:
        return False
    
    # Only promote tier 1 (public) or tier 2 (shared/anonymized)
    tier = analysis.get("tier", 3)
    if tier > 2:
        return False
    
    category = analysis.get("category", "knowledge")
    
    # Map to valid Supabase categories
    cat_map = {
        "failure": "failure",
        "friction": "friction",
        "safety": "safety",
        "build": "build",
        "operational": "operational",
        "knowledge": "knowledge",
    }
    supabase_cat = cat_map.get(category, "knowledge")
    
    payload = {
        "source_id": "12cd9959-9fcc-47ca-b0dc-54e7e972f8e9",  # Recon source
        "category": supabase_cat,
        "summary": f"Chat insight from {original_msg.get('sender', 'unknown')}: {analysis.get('summary', '')[:100]}",
        "tier": tier,
        "usefulness_score": analysis.get("usefulness_score", 7),
        "status": "received",
        "submission_confidence": 60,
        "evidence_type": "chat_scan",
        "processing_status": "classified",
        "secret_scan_result": analysis.get("secret_scan", "clear"),
        "meta": {
            "source": "chat_intelligence_scanner",
            "original_sender": original_msg.get("sender"),
            "message_id": original_msg.get("id"),
            "analysis_category": category,
            "scan_timestamp": datetime.now(timezone.utc).isoformat(),
        }
    }
    
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/submissions",
        headers=headers,
        json=payload
    )
    
    return r.status_code in (200, 201)

# Main scan
messages = get_recent_messages()
print(f"Found {len(messages)} messages in last {SCAN_WINDOW_MINUTES} minutes")

if not messages:
    print("No recent messages to scan")
else:
    processed = 0
    promoted = 0
    skipped = 0
    
    for msg in messages:
        msg_text = msg.get("message", "")
        sender = msg.get("sender", "unknown")
        
        # Skip empty or very short messages
        if len(msg_text) < 20:
            skipped += 1
            continue
        
        # Skip system/recon's own messages
        if sender == "Recon" or "system" in msg_text.lower():
            skipped += 1
            continue
        
        # Analyze the message
        analysis = analyze_message(msg_text, sender)
        
        if analysis:
            processed += 1
            usefulness = analysis.get("usefulness_score", 0)
            category = analysis.get("category", "unknown")
            
            if usefulness >= MIN_USEFULNESS:
                success = create_knowledge_unit(analysis, msg)
                if success:
                    promoted += 1
                    print(f"PROMOTED [{category}] score={usefulness} from {sender}: {msg_text[:60]}...")
                else:
                    skipped += 1
            else:
                skipped += 1
                print(f"Skipped (low signal) score={usefulness} from {sender}")
        else:
            skipped += 1
    
    print(f"Scan complete: {processed} analyzed, {promoted} promoted, {skipped} skipped")

PYEOF

log "Chat intelligence scan finished"
