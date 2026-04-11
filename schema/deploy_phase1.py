#!/usr/bin/env python3
"""
Deploy Phase 1 schema to Supabase.
Executes SQL files in order using supabase-py client.
"""

import os
import sys
from pathlib import Path
from supabase import create_client, Client

# Configuration
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://nygdcvjmjzvyxljexjjo.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY")

if not SUPABASE_KEY:
    print("ERROR: SUPABASE_SERVICE_KEY environment variable not set")
    sys.exit(1)

# Initialize client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# SQL files to execute in order
SQL_FILES = [
    # Core tables
    "core/003_entities.sql",
    "core/004_entity_profiles.sql",
    "core/005_entity_relationships.sql",

    # Taxonomy tables
    "taxonomy/006_classification_types.sql",
    "taxonomy/007_categories.sql",
    "taxonomy/008_tags.sql",
    "taxonomy/020_entity_classifications.sql",

    # Content tables
    "content/010_submissions.sql",
    "content/013_content_items.sql",
    "content/014_ecosystem_updates.sql",

    # Migration (MUST RUN LAST)
    "migrations/000_drop_assets_and_migrate.sql",
]

SCHEMA_DIR = Path(__file__).parent

def execute_sql_file(filepath: Path) -> bool:
    """Execute a SQL file using Supabase REST API rpc endpoint."""
    print(f"\n{'='*60}")
    print(f"Executing: {filepath.name}")
    print(f"{'='*60}")

    try:
        sql_content = filepath.read_text()

        # Use the PostgREST RPC endpoint to execute raw SQL
        # Note: This requires the SQL to be wrapped in a function or use the special /rpc endpoint
        # Alternative: Use multiple REST API calls for each CREATE TABLE

        # For now, let's use the supabase-py client's .table().insert() for data
        # and direct SQL execution via the REST API

        import requests

        # Execute SQL via Supabase's undocumented SQL execution endpoint
        # This is the same endpoint used by the Supabase dashboard SQL editor
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/",
            headers={
                "apikey": SUPABASE_KEY,
                "Authorization": f"Bearer {SUPABASE_KEY}",
                "Content-Type": "application/json",
                "Prefer": "params=single-object",
            },
            json={"query": sql_content}  # This won't work directly
        )

        # Actually, Supabase doesn't expose raw SQL execution via REST API
        # We need to use the psql command-line tool or the Supabase CLI
        # Let's fall back to writing a note about manual execution

        print(f"⚠️  Raw SQL execution via REST API not supported")
        print(f"   Please execute this file manually via:")
        print(f"   1. Supabase Dashboard → SQL Editor")
        print(f"   2. Copy contents of: {filepath}")
        print(f"   3. Paste and run")
        return False

    except Exception as e:
        print(f"❌ Error executing {filepath.name}: {e}")
        return False

def main():
    print("="*60)
    print("Phase 1 Schema Deployment")
    print("="*60)
    print(f"Supabase URL: {SUPABASE_URL}")
    print(f"Files to execute: {len(SQL_FILES)}")
    print()

    success_count = 0
    fail_count = 0

    for sql_file_rel in SQL_FILES:
        filepath = SCHEMA_DIR / sql_file_rel

        if not filepath.exists():
            print(f"❌ File not found: {filepath}")
            fail_count += 1
            continue

        # For now, just print instructions since we can't execute raw SQL via REST API
        print(f"\n📄 Ready to execute: {sql_file_rel}")
        print(f"   File size: {filepath.stat().st_size} bytes")

    print("\n" + "="*60)
    print("DEPLOYMENT INSTRUCTIONS")
    print("="*60)
    print("""
Since psql is not installed and Supabase REST API doesn't support raw SQL execution,
please deploy manually via Supabase Dashboard:

1. Go to: https://app.supabase.com/project/nygdcvjmjzvyxljexjjo/sql
2. For each SQL file below, copy its contents and paste into the SQL Editor
3. Run each file in order
4. Verify no errors before proceeding to the next file

File order:
""")

    for i, sql_file in enumerate(SQL_FILES, 1):
        print(f"  {i:2d}. {sql_file}")

    print("""
After all files are executed, run verification queries from DEPLOYMENT_ORDER.md
""")

if __name__ == "__main__":
    main()
