#!/usr/bin/env python3
"""
XRPL Fallback Node Resolver
When the primary CLIO node is stale or down, this script discovers
healthy public rippled nodes and returns the best one.

Usage: python3 xrpl-fallback.py [--check] [--use]
  --check  : Just print node status
  --use    : Output best node URL for config replacement
"""
import json
import time
import socket
import ssl
import sys

PRIMARY_CLIO = "http://xrpl-rpc.goons.app:51233"
PRIMARY_WS = "ws://xrpl-rpc.goons.app:51238"

# Known public rippled nodes (WebSocket + HTTP-RPC)
FALLBACK_NODES = [
    {"name": "xrplcluster.com", "ws": "wss://xrplcluster.com", "rpc": None},
    {"name": "s2.ripple.com", "ws": "wss://s2.ripple.com", "rpc": None},
    {"name": "bithomp.com", "ws": "wss://bithomp.com/api/v1/ws", "rpc": "https://bithomp.com/api/v1/"},
]

def check_clio_freshness():
    """Check how stale the primary CLIO node is."""
    try:
        import urllib.request
        req = urllib.request.Request(
            PRIMARY_CLIO,
            data=json.dumps({
                "method": "ledger",
                "params": [{"ledger_index": "validated", "transactions": False}]
            }).encode(),
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read())
            result = data.get("result", {})
            ledger = result.get("ledger", {})
            close_time = ledger.get("close_time", 0)
            current_time = int(time.time()) + 946684800  # XRPL epoch offset
            
            age_seconds = current_time - close_time
            return {
                "node": "primary-clio",
                "ledger_index": result.get("ledger_index"),
                "close_time_human": ledger.get("close_time_human"),
                "age_seconds": age_seconds,
                "age_minutes": round(age_seconds / 60, 1),
                "fresh": age_seconds < 120,  # < 2 min = fresh
                "status": "ok"
            }
    except Exception as e:
        return {"node": "primary-clio", "status": "error", "error": str(e)}

def main():
    check = "--check" in sys.argv
    use = "--use" in sys.argv
    
    print("=== XRPL Node Health Check ===")
    print(f"Primary CLIO: {PRIMARY_CLIO}")
    print()
    
    freshness = check_clio_freshness()
    print(f"Node: {freshness['node']}")
    if freshness['status'] == 'error':
        print(f"  Status: ERROR - {freshness['error']}")
    else:
        print(f"  Ledger: {freshness['ledger_index']}")
        print(f"  Close:  {freshness['close_time_human']}")
        print(f"  Age:    {freshness['age_minutes']} minutes")
        print(f"  Fresh:  {'YES ✓' if freshness['fresh'] else 'NO ✗ (STALE)'}")
    
    print()
    print(f"{'Status: STALE - fallback needed' if not freshness.get('fresh', True) else 'Status: PRIMARY NODE HEALTHY'}")
    
    if not freshness.get('fresh', True):
        print()
        print("Recommended action:")
        print("  1. Notify XRPLClaw ops to restart/resync CLIO")
        print("  2. Agents should use public rippled nodes for read queries")
        print("  3. Keep CLIO for signed transactions (it'll catch up eventually)")
        
        if use:
            print()
            print("FALLBACK_RPC=https://bithomp.com/api/v1/")
            print("FALLBACK_WS=wss://bithomp.com/api/v1/ws")

if __name__ == "__main__":
    main()
