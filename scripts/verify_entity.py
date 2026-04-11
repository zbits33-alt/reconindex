#!/usr/bin/env python3
"""
Verify or un-verify an entity in the Recon Index.
Usage: python scripts/verify_entity.py <entity_name> [true|false]
"""

import os
import sys
import requests

SUPABASE_URL = "https://nygdcvjmjzvyxljexjjo.supabase.co"
SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY")

if not SERVICE_KEY:
    print("ERROR: SUPABASE_SERVICE_KEY environment variable is required.")
    sys.exit(1)

def get_entity_id(name):
    """Find the entity ID by name."""
    url = f"{SUPABASE_URL}/rest/v1/entities?name=eq.{name}&select=id"
    headers = {
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}"
    }
    response = requests.get(url, headers=headers)
    if response.status_code == 200 and len(response.json()) > 0:
        return response.json()[0]['id']
    return None

def update_verification(entity_id, is_verified):
    """Update the verified status in entity_profiles."""
    # First check if profile exists
    url = f"{SUPABASE_URL}/rest/v1/entity_profiles?entity_id=eq.{entity_id}&select=id"
    headers = {
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}"
    }
    
    response = requests.get(url, headers=headers)
    
    data = {"verified": is_verified}
    
    if response.status_code == 200 and len(response.json()) > 0:
        # Update existing profile
        url = f"{SUPABASE_URL}/rest/v1/entity_profiles?entity_id=eq.{entity_id}"
        response = requests.patch(url, headers=headers, json=data)
    else:
        # Create new profile
        url = f"{SUPABASE_URL}/rest/v1/entity_profiles"
        data["entity_id"] = entity_id
        data["slug"] = "unknown" # Should be updated manually
        response = requests.post(url, headers=headers, json=data)

    return response.status_code == 200 or response.status_code == 201

def main():
    if len(sys.argv) < 2:
        print("Usage: python scripts/verify_entity.py <entity_name> [true|false]")
        print("Example: python scripts/verify_entity.py Predator true")
        sys.exit(1)

    name = sys.argv[1]
    status = sys.argv[2].lower() == "true" if len(sys.argv) > 2 else True

    print(f"Looking for entity: {name}...")
    entity_id = get_entity_id(name)
    
    if not entity_id:
        print(f"❌ Entity '{name}' not found.")
        sys.exit(1)

    print(f"Updating verification status to: {status}...")
    if update_verification(entity_id, status):
        print(f"✅ Success! '{name}' is now {'verified' if status else 'unverified'}.")
    else:
        print("❌ Failed to update verification status.")

if __name__ == "__main__":
    main()
