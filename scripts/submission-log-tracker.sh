#!/bin/bash
# ═══════════════════════════════════════════════════════
# SUBMISSION LOG TRACKER
# Builds a categorized log of all submissions by source
# Output: logs/submission-log.json (updated each run)
# ═══════════════════════════════════════════════════════

LOG_DIR="/home/agent/workspace/logs"
OUTPUT="$LOG_DIR/submission-log.json"
mkdir -p "$LOG_DIR"

python3 << 'PYEOF'
import requests, json
from datetime import datetime, timezone

SUPABASE_URL = "https://nygdcvjmjzvyxljexjjo.supabase.co"

# Read service key
with open("/home/agent/workspace/memory/secrets.md") as f:
    for line in f:
        if line.startswith("supabase_service_role="):
            SERVICE_KEY = line.strip().split("=", 1)[1]
            break

headers = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
}

# Fetch all sources with profiles
r = requests.get(f"{SUPABASE_URL}/rest/v1/sources?select=id,name,source_type,owner_name,internal_notes", headers=headers)
sources_list = r.json() if r.status_code == 200 else []

# Build source lookup
source_map = {}
for src in sources_list:
    profile = None
    classification = None
    notes = src.get("internal_notes")
    if notes:
        try:
            notes_data = json.loads(notes)
            profile = notes_data.get("agent_profile")
            classification = notes_data.get("classification")
        except:
            pass

    source_map[src["id"]] = {
        "name": src["name"],
        "source_type": src.get("source_type", "unknown"),
        "owner": src.get("owner_name"),
        "profile": profile,
        "classification": classification,
        "category_path": profile.get("category_path") if profile else "unclassified",
    }

# Fetch all submissions
r = requests.get(f"{SUPABASE_URL}/rest/v1/submissions?select=id,source_id,category,summary,tier,usefulness_score,status,submitted_at,meta&order=submitted_at.desc&limit=500", headers=headers)
submissions = r.json() if r.status_code == 200 else []

# Build submission log grouped by source
log_by_source = {}
for sub in submissions:
    src_id = sub.get("source_id")
    src_info = source_map.get(src_id, {"name": "unknown", "source_type": "unknown", "category_path": "unclassified"})

    if src_id not in log_by_source:
        log_by_source[src_id] = {
            "source_name": src_info["name"],
            "source_type": src_info["source_type"],
            "category_path": src_info["category_path"],
            "total_submissions": 0,
            "categories": {},
            "recent": [],
        }

    entry = log_by_source[src_id]
    entry["total_submissions"] += 1

    cat = sub.get("category", "unknown")
    entry["categories"][cat] = entry["categories"].get(cat, 0) + 1

    # Track recent submissions (last 5 per source)
    if len(entry["recent"]) < 5:
        entry["recent"].append({
            "id": sub["id"][:8],
            "category": cat,
            "summary": sub.get("summary", "")[:100],
            "usefulness": sub.get("usefulness_score", 0),
            "submitted_at": sub.get("submitted_at", "")[:19],
        })

# Build category distribution across all sources
all_categories = {}
for sub in submissions:
    cat = sub.get("category", "unknown")
    all_categories[cat] = all_categories.get(cat, 0) + 1

# Build final log
submission_log = {
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "total_sources": len(source_map),
    "sources_with_submissions": len(log_by_source),
    "total_submissions": len(submissions),
    "category_distribution": dict(sorted(all_categories.items(), key=lambda x: -x[1])),
    "sources": dict(sorted(log_by_source.items(), key=lambda x: -x[1]["total_submissions"])),
}

# Write to file
OUTPUT = "/home/agent/workspace/logs/submission-log.json"
with open(OUTPUT, "w") as f:
    json.dump(submission_log, f, indent=2)

print(f"Submission log written to {OUTPUT}")
print(f"Total sources: {submission_log['total_sources']}")
print(f"Sources with submissions: {submission_log['sources_with_submissions']}")
print(f"Total submissions: {submission_log['total_submissions']}")
print(f"\nCategory distribution:")
for cat, count in submission_log["category_distribution"].items():
    print(f"  {cat}: {count}")
PYEOF

echo "[$(date -u +'%H:%M:%S')] [SUB-LOG] Submission log updated" >> "$LOG_DIR/submission-log.log"
