#!/usr/bin/env python3
"""
Recon — XRPL Amendment Indexer
Fetches live amendment data from private XRPL node + supplemental info from xrpl.org docs.
Outputs structured JSON + markdown summary to intelligence/amendments/
Runs on schedule via Recon cron.
"""

import json
import os
import requests
from datetime import datetime, timezone

XRPL_RPC = "http://xrpl-rpc.goons.app:51233"
OUT_DIR = "/home/agent/workspace/intelligence/amendments"
XRPL_AMENDMENTS_URL = "https://xrpl.org/known-amendments.html"

def rpc(method, params=None):
    payload = {"method": method, "params": [params or {}]}
    r = requests.post(XRPL_RPC, json=payload, timeout=15)
    return r.json().get("result", {})

def fetch_amendments():
    result = rpc("feature")
    features = result.get("features", {})
    
    enabled = {}
    pending = {}
    vetoed = {}
    
    for hash_key, data in features.items():
        name = data.get("name", f"unknown-{hash_key[:8]}")
        entry = {
            "hash": hash_key,
            "name": name,
            "supported": data.get("supported", False),
            "vetoed": data.get("vetoed", False),
            "enabled": data.get("enabled", False),
            "count": data.get("count"),
            "threshold": data.get("threshold"),
            "majority_time": data.get("majority", {}).get("since") if data.get("majority") else None,
        }
        if data.get("enabled"):
            enabled[name] = entry
        elif data.get("vetoed"):
            vetoed[name] = entry
        else:
            pending[name] = entry
    
    return {"enabled": enabled, "pending": pending, "vetoed": vetoed}

def fetch_xrplto_amendments():
    """Scrape xrpl.to for amendment adoption rates and validator support."""
    try:
        r = requests.get("https://xrpl.to/amendments", timeout=15, headers={"User-Agent": "Recon-Indexer/1.0"})
        # Return raw for parsing — we'll extract key info
        return {"status": r.status_code, "length": len(r.text), "sample": r.text[:500]}
    except Exception as e:
        return {"error": str(e)}

def fetch_evernode_docs():
    """Fetch Evernode documentation index."""
    urls = [
        "https://docs.evernode.org/en/latest/",
        "https://docs.evernode.org/en/latest/sdk/hotpocket/reference/",
        "https://docs.evernode.org/en/latest/sdk/evernode/",
    ]
    results = {}
    for url in urls:
        try:
            r = requests.get(url, timeout=15, headers={"User-Agent": "Recon-Indexer/1.0"})
            results[url] = {"status": r.status_code, "length": len(r.text)}
        except Exception as e:
            results[url] = {"error": str(e)}
    return results

def write_json(data, filename):
    path = os.path.join(OUT_DIR, filename)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    return path

def write_markdown(amendments, timestamp):
    enabled = amendments["enabled"]
    pending = amendments["pending"]
    vetoed = amendments["vetoed"]
    
    lines = [
        f"# XRPL Amendment Index",
        f"> Updated: {timestamp}",
        f"> Source: Private XRPL CLIO node (xrpl-rpc.goons.app)",
        f"",
        f"## Summary",
        f"| Status | Count |",
        f"|--------|-------|",
        f"| ✅ Enabled | {len(enabled)} |",
        f"| 🟡 Pending | {len(pending)} |",
        f"| ❌ Vetoed | {len(vetoed)} |",
        f"",
        f"## Pending Amendments ({len(pending)})",
        f"> These are not yet active on mainnet. Watch for validator adoption.",
        f"",
        f"| Name | Validators | Threshold | Majority Since |",
        f"|------|-----------|-----------|----------------|",
    ]
    
    for name, data in sorted(pending.items()):
        count = data.get("count") or "—"
        threshold = data.get("threshold") or "—"
        majority = data.get("majority_time") or "—"
        lines.append(f"| {name} | {count} | {threshold} | {majority} |")
    
    lines += [
        f"",
        f"## Vetoed Amendments ({len(vetoed)})",
        f"",
    ]
    for name in sorted(vetoed.keys()):
        lines.append(f"- {name}")
    
    lines += [
        f"",
        f"## Enabled Amendments ({len(enabled)})",
        f"",
    ]
    for name in sorted(enabled.keys()):
        lines.append(f"- {name}")
    
    path = os.path.join(OUT_DIR, "amendments_latest.md")
    with open(path, "w") as f:
        f.write("\n".join(lines))
    return path

def main():
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    print(f"[{timestamp}] Recon Amendment Indexer starting...")

    # 1. Fetch live amendment data
    print("  Fetching amendments from XRPL node...")
    amendments = fetch_amendments()
    print(f"  Found: {len(amendments['enabled'])} enabled, {len(amendments['pending'])} pending, {len(amendments['vetoed'])} vetoed")

    # 2. Save full JSON snapshot
    snapshot = {
        "updated": timestamp,
        "source": XRPL_RPC,
        "summary": {
            "enabled_count": len(amendments["enabled"]),
            "pending_count": len(amendments["pending"]),
            "vetoed_count": len(amendments["vetoed"]),
        },
        "amendments": amendments,
    }
    json_path = write_json(snapshot, "amendments_latest.json")
    print(f"  Saved JSON: {json_path}")

    # 3. Save historical snapshot with timestamp
    hist_path = write_json(snapshot, f"snapshot_{timestamp.replace(':', '-')}.json")
    print(f"  Saved snapshot: {hist_path}")

    # 4. Write markdown summary
    md_path = write_markdown(amendments, timestamp)
    print(f"  Saved markdown: {md_path}")

    # 5. Check xrpl.to
    print("  Checking xrpl.to amendments page...")
    xrplto = fetch_xrplto_amendments()
    with open(os.path.join(OUT_DIR, "xrplto_check.json"), "w") as f:
        json.dump({"timestamp": timestamp, "result": xrplto}, f, indent=2)

    # 6. Check Evernode docs
    print("  Checking Evernode docs...")
    evernode = fetch_evernode_docs()
    with open("/home/agent/workspace/intelligence/evernode/docs_check.json", "w") as f:
        json.dump({"timestamp": timestamp, "result": evernode}, f, indent=2)

    # 7. Detect changes from last run
    changelog_path = os.path.join(OUT_DIR, "changelog.md")
    prev_path = os.path.join(OUT_DIR, "amendments_prev.json")
    if os.path.exists(prev_path):
        with open(prev_path) as f:
            prev = json.load(f)
        prev_pending = set(prev.get("amendments", {}).get("pending", {}).keys())
        prev_enabled = set(prev.get("amendments", {}).get("enabled", {}).keys())
        curr_pending = set(amendments["pending"].keys())
        curr_enabled = set(amendments["enabled"].keys())

        newly_enabled = curr_enabled - prev_enabled
        newly_pending = curr_pending - prev_pending
        dropped_pending = prev_pending - curr_pending - curr_enabled

        if newly_enabled or newly_pending or dropped_pending:
            with open(changelog_path, "a") as f:
                f.write(f"\n## {timestamp}\n")
                for name in newly_enabled:
                    f.write(f"- ✅ ENABLED: {name}\n")
                for name in newly_pending:
                    f.write(f"- 🟡 NEW PENDING: {name}\n")
                for name in dropped_pending:
                    f.write(f"- ❌ DROPPED FROM PENDING: {name}\n")
            print(f"  Changes detected — changelog updated")
        else:
            print(f"  No changes since last run")

    # Save current as prev for next run
    import shutil
    shutil.copy(json_path, prev_path)

    print(f"[{timestamp}] Done.")

if __name__ == "__main__":
    main()
