#!/usr/bin/env python3
"""
Execute Phase 1 schema deployment via Supabase Management API.
Uses the service role key to execute raw SQL.
"""

import os
import sys
import requests
from pathlib import Path

SUPABASE_URL = "https://nygdcvjmjzvyxljexjjo.supabase.co"
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY")
SCHEMA_DIR = Path("/home/agent/workspace/schema")

if not SUPABASE_KEY:
    print("ERROR: SUPABASE_SERVICE_KEY not set")
    sys.exit(1)

# SQL files in execution order
SQL_FILES = [
    "core/003_entities.sql",
    "core/004_entity_profiles.sql",
    "core/005_entity_relationships.sql",
    "taxonomy/006_classification_types.sql",
    "taxonomy/007_categories.sql",
    "taxonomy/008_tags.sql",
    "taxonomy/020_entity_classifications.sql",
    "content/010_submissions.sql",
    "content/013_content_items.sql",
    "content/014_ecosystem_updates.sql",
    "migrations/000_drop_assets_and_migrate.sql",
]

def execute_sql(sql_content: str, filename: str) -> bool:
    """Execute SQL via Supabase Management API."""
    print(f"\n{'='*60}")
    print(f"Executing: {filename}")
    print(f"{'='*60}")

    # Use the Supabase SQL execution endpoint
    # This is the same endpoint used by the dashboard SQL editor
    url = f"{SUPABASE_URL}/rest/v1/"

    # For raw SQL execution, we need to use a different approach
    # Supabase doesn't expose raw SQL via REST API directly
    # We'll use the pgcrypto extension trick or split into individual statements

    # Actually, let's try using the Supabase CLI's db query command with --linked
    # But first, let's try a direct HTTP approach using the management API

    # The correct way: Use the Supabase Management API's SQL execution endpoint
    # Endpoint: POST /project/{ref}/sql
    mgmt_url = f"https://api.supabase.com/v1/projects/nygdcvjmjzvyxljexjjo/sql"

    headers = {
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "query": sql_content,
    }

    try:
        response = requests.post(mgmt_url, headers=headers, json=payload, timeout=30)

        if response.status_code == 200:
            print(f"✅ Success: {filename}")
            return True
        else:
            print(f"❌ Error ({response.status_code}): {response.text[:500]}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

def main():
    print("="*60)
    print("Phase 1 Schema Deployment")
    print("="*60)
    print(f"Project: {SUPABASE_URL}")
    print(f"Files: {len(SQL_FILES)}")
    print()

    success_count = 0
    fail_count = 0

    for sql_file_rel in SQL_FILES:
        filepath = SCHEMA_DIR / sql_file_rel

        if not filepath.exists():
            print(f"❌ File not found: {filepath}")
            fail_count += 1
            continue

        sql_content = filepath.read_text()

        if execute_sql(sql_content, sql_file_rel):
            success_count += 1
        else:
            fail_count += 1
            print(f"\n⚠️  Stopping deployment due to error in {sql_file_rel}")
            print(f"   Please fix the issue and re-run from this file.")
            break

    print("\n" + "="*60)
    print(f"Deployment Complete: {success_count} succeeded, {fail_count} failed")
    print("="*60)

    if fail_count == 0:
        print("\n✅ All files executed successfully!")
        print("\nNext steps:")
        print("1. Run verification queries (see DEPLOYMENT_ORDER.md)")
        print("2. Re-enable crons:")
        print("   openclaw cron update 63ca50e8... --patch '{\"enabled\":true}'")
        print("   openclaw cron update e1294497... --patch '{\"enabled\":true}'")
    else:
        print("\n⚠️  Some files failed. Check errors above.")

if __name__ == "__main__":
    main()
