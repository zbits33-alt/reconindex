#!/bin/bash
# ═══════════════════════════════════════════════════════
# LIBRARIES SYNC — Pulls collections/index → site JSON
# Runs every 15 min via system crontab (zero agent cost)
# Updates: entries, patterns, categories, library candidates
# ═══════════════════════════════════════════════════════

LOG="/home/agent/workspace/logs/self-heal.log"
mkdir -p /home/agent/workspace/reconindex-site/api

log() { echo "[$(date -u +'%H:%M:%S')] [LIBSYNC] $1" >> "$LOG"; }
log "Libraries sync started"

python3 << 'PYEOF'
import json, os, re, glob

BASE = "/home/agent/workspace"
COLLECTIONS = os.path.join(BASE, "collections")
OUTPUT = os.path.join(BASE, "reconindex-site", "api", "libraries.json")

def parse_index():
    entries = []
    idx = os.path.join(COLLECTIONS, "INDEX.md")
    if not os.path.exists(idx):
        return entries
    with open(idx) as f:
        in_table = False
        for line in f:
            if line.startswith("| ID |"):
                in_table = True
                continue
            if not in_table or not line.startswith("| RECON-"):
                continue
            parts = [p.strip() for p in line.strip().split("|") if p.strip()]
            if len(parts) >= 8:
                entries.append({
                    "id": parts[0],
                    "type": parts[1],
                    "title": parts[2],
                    "usefulness": int(parts[3]) if parts[3].isdigit() else 0,
                    "frequency": int(parts[4]) if parts[4].isdigit() else 0,
                    "priority": float(parts[5]) if _is_float(parts[5]) else 0,
                    "library_candidate": "YES" in parts[6],
                    "file": parts[7],
                })
    return entries

def _is_float(s):
    try: float(s); return True
    except: return False

def load_file_preview(filepath, max_chars=400):
    full = os.path.join(COLLECTIONS, filepath)
    if os.path.exists(full):
        with open(full) as f:
            content = f.read()
            # Skip frontmatter
            if content.startswith("#"):
                content = content.split("\n", 1)[-1] if "\n" in content else content
            return content[:max_chars].strip()
    return ""

def count_patterns():
    pdir = os.path.join(COLLECTIONS, "patterns")
    if not os.path.exists(pdir): return 0
    return len([f for f in os.listdir(pdir) if f.endswith(".md") and f != "PATTERN_FORMAT.md"])

def count_agents():
    reg = os.path.join(COLLECTIONS, "agents", "SOURCE_REGISTRY.md")
    if not os.path.exists(reg): return 0
    with open(reg) as f:
        content = f.read()
    matches = re.findall(r'\| SRC-\d+ \|', content)
    return max(len(matches) - 1, 0)

# Parse
entries = parse_index()

# Group by type
categories = {}
for e in entries:
    t = e["type"]
    if t not in categories: categories[t] = []
    categories[t].append(e)

# Sort each category by priority desc
for cat in categories:
    categories[cat].sort(key=lambda x: x["priority"], reverse=True)

# Build library candidate list
library_candidates = [e for e in entries if e["library_candidate"]]
library_candidates.sort(key=lambda x: x["priority"], reverse=True)

# Load previews for top entries
top_entries = []
for e in sorted(entries, key=lambda x: x["priority"], reverse=True)[:8]:
    e["preview"] = load_file_preview(e["file"])
    top_entries.append(e)

data = {
    "updated": __import__("datetime").datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "total_entries": len(entries),
    "total_patterns": count_patterns(),
    "total_agents": count_agents(),
    "library_candidates": len(library_candidates),
    "categories": {k: {"count": len(v), "entries": [{"id": x["id"], "title": x["title"], "usefulness": x["usefulness"], "priority": x["priority"]} for x in v]} for k, v in categories.items()},
    "top_entries": [{"id": x["id"], "type": x["type"], "title": x["title"], "usefulness": x["usefulness"], "priority": x["priority"], "preview": x.get("preview", "")} for x in top_entries],
    "library_candidates_list": [{"id": x["id"], "title": x["title"], "type": x["type"], "priority": x["priority"]} for x in library_candidates[:20]],
}

os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
with open(OUTPUT, "w") as f:
    json.dump(data, f, indent=2)

print(f"Libraries synced: {data['total_entries']} entries, {data['total_patterns']} patterns, {data['total_agents']} agents, {data['library_candidates']} candidates")
PYEOF

log "Libraries sync complete"
