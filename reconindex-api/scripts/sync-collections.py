#!/usr/bin/env python3
"""
Sync local workspace collections → Supabase Recon Index.

Reads markdown files from collections/ and intelligence/, creates
submissions and knowledge_units in Supabase so the data lives in the
central DB, not just local files.

Usage: python3 scripts/sync-collections.py [--dry-run] [--limit 10]
"""

import os, sys, re, json, hashlib
from datetime import datetime, timezone

def log(msg):
    print(f"[sync] {msg}")

BASE = "https://nygdcvjmjzvyxljexjjo.supabase.co"
API_KEY = os.environ.get("SUPABASE_SERVICE_KEY")
if not API_KEY:
    log("ERROR: SUPABASE_SERVICE_KEY environment variable not set")
    sys.exit(1)
HEADERS = {
    "apikey": API_KEY,
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

COLLECTIONS_DIR = "/home/agent/workspace/collections"
INTELLIGENCE_DIR = "/home/agent/workspace/intelligence"
AGENTS_DIR = "/home/agent/workspace/agents"

# Map collection categories to valid submission categories
# Valid: identity, build, operational, performance, failure, knowledge, safety, friction, audit_request
VALID_CATEGORIES = {"identity", "build", "operational", "performance", "failure", "knowledge", "safety", "friction", "audit_request"}

def map_category(cat):
    """Map collection folder name to a valid submission category."""
    mapping = {
        "safety": "safety",
        "failure": "failure",
        "failures": "failure",
        "friction": "friction",
        "tools": "knowledge",
        "platform": "operational",
        "agent_intel": "operational",
        "ecosystem": "knowledge",
        "pattern": "knowledge",
        "cost_index": "operational",
        "amendments": "knowledge",
        "evernode": "knowledge",
    }
    return mapping.get(cat, "knowledge")

FOLDER_MAP = {
    "safety":     {"category": "safety",       "source_name": "Recon"},
    "failures":   {"category": "failure",       "source_name": "Recon"},
    "friction":   {"category": "friction",      "source_name": "Recon"},
    "tools":      {"category": "tools",          "source_name": "Recon"},
    "platform":   {"category": "platform",       "source_name": "Recon"},
    "agents":     {"category": "agent_intel",    "source_name": "Recon"},
    "ecosystem":  {"category": "ecosystem",      "source_name": "Recon"},
    "patterns":   {"category": "pattern",        "source_name": "Recon"},
    "cost":       {"category": "cost_index",     "source_name": "Recon"},
    "amendments": {"category": "amendments",     "source_name": "Recon"},
    "evernode":   {"category": "evernode",       "source_name": "Recon"},
}

SKIP_FILES = {
    "INDEX.md", "STAGING_FORMAT.md", "SUBMISSION_FORMAT.md",
    "AGENT_CONNECTION_PROTOCOL.md", "RECON_PHASE1_AUDIT.md",
    "RECON_SCRIPTS_INDEX.md", "SOURCE_REGISTRY.md",
    "PATTERN_FORMAT.md", "active_patterns.md",
    "xrplpulse_catalog.md", "xrplpulse_intelligence.md",
}

# Agent-specific files to skip (operational state, not intelligence)
AGENT_SKIP = {"STATE.md", "config.json"}


def import_requests():
    import requests
    return requests


def get_sources(requests):
    r = requests.get(f"{BASE}/rest/v1/sources?select=id,name,source_code,status", headers={
        "apikey": API_KEY, "Authorization": f"Bearer {API_KEY}"
    })
    data = r.json()
    sources = data if isinstance(data, list) else data.get("data", [])
    lookup = {}
    for s in sources:
        lookup[s["name"]] = s["id"]
        if s.get("source_code"):
            lookup[s["source_code"]] = s["id"]
    return lookup


def generate_code(prefix, name):
    h = hashlib.md5(f"{prefix}-{name}-{datetime.now().isoformat()}".encode()).hexdigest()[:8]
    return f"{prefix}-{h}"


def read_markdown(filepath):
    with open(filepath, "r") as f:
        content = f.read()

    title_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    title = title_match.group(1).strip() if title_match else os.path.basename(filepath).replace(".md", "").replace("_", " ").title()

    lines = content.split("\n")
    in_frontmatter = False
    summary_lines = []
    for line in lines:
        if line.strip() == "---":
            in_frontmatter = not in_frontmatter
            continue
        if in_frontmatter:
            continue
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        if stripped:
            summary_lines.append(stripped)
            if len(" ".join(summary_lines)) > 200:
                break

    summary = " ".join(summary_lines)[:500]
    return title, summary, content


def sync_file(requests, filepath, source_id, category, dry_run=False):
    rel = os.path.relpath(filepath, "/home/agent/workspace")
    title, summary, content = read_markdown(filepath)
    file_hash = hashlib.md5(content.encode()).hexdigest()

    # Check if already synced (avoid duplicates)
    import urllib.parse
    check_url = f"{BASE}/rest/v1/submissions?select=id&meta->>file_hash=eq.{file_hash}"
    r_check = requests.get(check_url, headers={"apikey": API_KEY, "Authorization": f"Bearer {API_KEY}"})
    if r_check.json():
        log(f"  ↺ Already synced: {title[:50]}")
        return None

    # Actual Supabase schema columns:
    # tier (smallint 1-4), category, summary, content (text), meta (jsonb),
    # status, usefulness_score (smallint), submission_confidence,
    # evidence_type, processing_status, secret_scan_result,
    # related_gap_id, followup_required, followup_reason, submission_code

    submission = {
        "submission_code": generate_code("SUB", os.path.basename(filepath)),
        "source_id": source_id,
        "tier": 2,  # shared
        "category": category,
        "summary": summary,
        "content": content,
        "status": "received",
        "usefulness_score": 7,
        "submission_confidence": 80,
        "evidence_type": "imported",
        "processing_status": "classified",
        "secret_scan_result": "clear",
        "followup_required": False,
        "meta": {"source": "workspace_sync", "file_path": rel, "title": title, "file_hash": file_hash}
    }

    if dry_run:
        log(f"  [DRY] submission: {title[:60]}")
        return None

    r = requests.post(f"{BASE}/rest/v1/submissions", headers=HEADERS, json=submission)
    if r.status_code not in (200, 201):
        log(f"  ✗ submission ERROR: {r.status_code} {r.text[:200]}")
        return None

    result = r.json()
    sub_id = result[0]["id"] if isinstance(result, list) else result.get("id")
    log(f"  ✓ submission: {title[:60]} ({sub_id[:8]})")

    # Create knowledge_unit (actual schema)
    ku = {
        "source_id": source_id,
        "submission_id": sub_id,
        "tier": 2,
        "category": category,
        "title": title,
        "summary": summary[:300],
        "key_insight": summary[:150],
        "tags": [category, "imported"],
        "usefulness_score": 7,
        "library_candidate": True,
        "freshness_status": "fresh",
        "confidence_score": 80,
        "source_confidence": "medium",
        "review_status": "unreviewed",
        "inferred_fields": {"source": "workspace_sync", "file_path": rel},
        "direct_evidence_fields": {}
    }

    r2 = requests.post(f"{BASE}/rest/v1/knowledge_units", headers=HEADERS, json=ku)
    if r2.status_code not in (200, 201):
        log(f"  ⚠ knowledge_unit: {r2.status_code} {r2.text[:200]}")
        return {"submission_id": sub_id, "ku_id": None}
    result2 = r2.json()
    ku_id = result2[0]["id"] if isinstance(result2, list) else result2.get("id")
    log(f"  ✓ knowledge_unit: {title[:60]} ({ku_id[:8]})")

    return {"submission_id": sub_id, "ku_id": ku_id}


def scan_agent_directories():
    """Find agent directories with output/ or cache/ files worth syncing."""
    agent_files = []
    if not os.path.isdir(AGENTS_DIR):
        return agent_files

    for agent_name in sorted(os.listdir(AGENTS_DIR)):
        agent_path = os.path.join(AGENTS_DIR, agent_name)
        if not os.path.isdir(agent_path):
            continue

        # Scan output/ and logs/ for markdown reports
        for subdir in ["output", "logs"]:
            subdir_path = os.path.join(agent_path, subdir)
            if not os.path.isdir(subdir_path):
                continue
            for fname in sorted(os.listdir(subdir_path)):
                if not fname.endswith(".md"):
                    continue
                filepath = os.path.join(subdir_path, fname)
                agent_files.append({
                    "path": filepath,
                    "category": "operational",
                    "source_name": agent_name
                })

    return agent_files


def main():
    requests = import_requests()

    dry_run = "--dry-run" in sys.argv
    limit = None
    if "--limit" in sys.argv:
        idx = sys.argv.index("--limit")
        limit = int(sys.argv[idx + 1])

    log(f"{'[DRY RUN] ' if dry_run else ''}Syncing workspace collections → Supabase")

    sources = get_sources(requests)
    recon_id = sources.get("Recon")
    if not recon_id:
        log("ERROR: Recon source not found")
        sys.exit(1)
    log(f"Recon source: {recon_id[:8]}")

    files_to_sync = []
    for folder, mapping in FOLDER_MAP.items():
        folder_path = os.path.join(COLLECTIONS_DIR, folder)
        if not os.path.isdir(folder_path):
            folder_path = os.path.join(INTELLIGENCE_DIR, folder)
            if not os.path.isdir(folder_path):
                continue

        for fname in sorted(os.listdir(folder_path)):
            if not fname.endswith(".md") or fname in SKIP_FILES:
                continue
            filepath = os.path.join(folder_path, fname)
            files_to_sync.append({
                "path": filepath,
                "category": mapping["category"],
                "source_name": mapping["source_name"]
            })

    # Also scan agent directories for operational reports
    agent_files = scan_agent_directories()
    files_to_sync.extend(agent_files)
    if agent_files:
        log(f"Agent files: {len(agent_files)}")

    log(f"Found {len(files_to_sync)} files to sync")

    synced = 0
    skipped_agents = 0
    for item in files_to_sync:
        if limit and synced >= limit:
            log(f"Limit reached ({limit})")
            break

        # Skip agent operational state files
        basename = os.path.basename(item["path"])
        if item["path"].startswith(AGENTS_DIR) and basename in AGENT_SKIP:
            skipped_agents += 1
            continue

        source_id = sources.get(item["source_name"], recon_id)
        cat = map_category(item["category"])
        result = sync_file(requests, item["path"], source_id, cat, dry_run)
        if result:
            synced += 1

    log(f"\nDone. Synced {synced}/{len(files_to_sync)} files. Skipped {skipped_agents} agent state files.")


if __name__ == "__main__":
    main()
