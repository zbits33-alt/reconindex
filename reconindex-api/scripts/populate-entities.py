#!/usr/bin/env python3
"""
Populate Supabase entities table with XRPL Pulse project catalog.

Reads collections/ecosystem/xrplpulse_catalog.md and inserts each project
as an entity record. Skips duplicates by name.

Usage: python3 scripts/populate-entities.py [--dry-run]
"""

import os, sys, re, json, urllib.request
from datetime import datetime, timezone

def log(msg):
    print(f"[populate-entities] {msg}")

BASE = "https://nygdcvjmjzvyxljexjjo.supabase.co"
API_KEY = os.environ.get("SUPABASE_SERVICE_KEY")
if not API_KEY:
    log("ERROR: SUPABASE_SERVICE_KEY environment variable not set")
    sys.exit(1)

HEADERS = {
    "apikey": API_KEY,
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
}

CATALOG_PATH = "/home/agent/workspace/collections/ecosystem/xrplpulse_catalog.md"

# Map XRPL Pulse categories to valid entity_types
CATEGORY_MAP = {
    "DEX": "defi_app",
    "Tools": "tool",
    "Gaming": "project",
    "DeFi": "defi_app",
    "Payments": "wallet",
    "Metaverse": "project",
    "Prediction Market": "defi_app",
    "DID": "protocol",
    "Media": "media",
    "NFT": "nft_project",
}

def parse_catalog(path):
    """Parse the markdown catalog and return list of (name, url, description, category)."""
    with open(path, 'r') as f:
        content = f.read()

    projects = []
    current_category = None

    for line in content.split('\n'):
        # Detect category headers like "## DEX (20 projects)"
        cat_match = re.match(r'^##\s+(\w[\w\s]+?)\s+\((\d+)\s+projects?\)', line)
        if cat_match:
            current_category = cat_match.group(1).strip()
            continue

        # Parse table rows: | Project | URL | Description |
        row_match = re.match(r'^\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|', line)
        if row_match and current_category:
            name = row_match.group(1).strip()
            url = row_match.group(2).strip()
            desc = row_match.group(3).strip()
            # Skip header rows
            if name.lower() == 'project' or url.startswith('http') is False:
                continue
            projects.append({
                'name': name,
                'url': url,
                'description': desc,
                'category': current_category,
            })

    return projects


def get_existing_names():
    """Fetch existing entity names to avoid duplicates."""
    url = f"{BASE}/rest/v1/entities?select=name"
    resp = urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS))
    data = json.loads(resp.read())
    return {e['name'].lower() for e in data}


def insert_entity(name, entity_type, description, ecosystem, stage="live"):
    """Insert a single entity into Supabase."""
    url = f"{BASE}/rest/v1/entities"
    payload = {
        "name": name,
        "entity_type": entity_type,
        "description": description[:500] if description else None,
        "ecosystem": ecosystem,
        "stage": stage,
        "meta": {"source": "xrplpulse_catalog", "ingested_at": datetime.now(timezone.utc).isoformat()},
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={**HEADERS, "Prefer": "return=representation"},
        method="POST"
    )
    try:
        resp = urllib.request.urlopen(req)
        result = json.loads(resp.read())
        return result[0] if result else None
    except Exception as e:
        log(f"  ERROR inserting {name}: {e}")
        return None


def main():
    dry_run = "--dry-run" in sys.argv

    log(f"Parsing catalog: {CATALOG_PATH}")
    projects = parse_catalog(CATALOG_PATH)
    log(f"Found {len(projects)} projects in catalog")

    if not projects:
        log("No projects found. Check catalog path.")
        sys.exit(1)

    log("Fetching existing entities...")
    existing = get_existing_names()
    log(f"Existing entities: {len(existing)}")

    new_projects = [p for p in projects if p['name'].lower() not in existing]
    log(f"New projects to insert: {len(new_projects)}")
    log(f"Skipping duplicates: {len(projects) - len(new_projects)}")

    if dry_run:
        log("DRY RUN — no inserts performed")
        for p in new_projects[:10]:
            entity_type = CATEGORY_MAP.get(p['category'], 'project')
            log(f"  Would insert: {p['name']} ({entity_type}) — {p['url']}")
        if len(new_projects) > 10:
            log(f"  ... and {len(new_projects) - 10} more")
        return

    inserted = 0
    errors = 0
    for i, p in enumerate(new_projects, 1):
        entity_type = CATEGORY_MAP.get(p['category'], 'project')
        ecosystem = ["XRPL"]
        if "EVM" in p.get('description', '') or "evm" in p.get('description', '').lower():
            ecosystem.append("XRPLEVM")

        result = insert_entity(p['name'], entity_type, p['description'], ecosystem)
        if result:
            inserted += 1
            if i % 10 == 0:
                log(f"  Progress: {i}/{len(new_projects)} ({inserted} inserted, {errors} errors)")
        else:
            errors += 1

    log(f"\nDone! Inserted: {inserted}, Errors: {errors}, Total processed: {len(new_projects)}")


if __name__ == "__main__":
    main()
