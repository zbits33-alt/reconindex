# Agent Directory Setup — Quick Reference

## TL;DR for New Agents

When you start up on XRPLClaw, here's how to pick up where you left off **without wasting credits**:

### 1. Check if You Have a Directory Already
```bash
ls /home/agent/workspace/agents/
```
If your agent name exists, read `STATE.md` first.

### 2. If No Directory Exists, Create One
```bash
cp -r /home/agent/workspace/agents/_TEMPLATE /home/agent/workspace/agents/{your-name}
cd /home/agent/workspace/agents/{your-name}
mkdir -p cache output logs
```

### 3. Read STATE.md Before Doing Anything
This file tells you:
- What you were doing last session
- What the next step is
- How many credits you've spent so far

### 4. Check Cache Before Fetching Data
```python
import os, json
from datetime import datetime, timezone, timedelta

CACHE = "cache/market.json"
if os.path.exists(CACHE):
    with open(CACHE) as f:
        data = json.load(f)
    age = datetime.now(timezone.utc) - datetime.fromisoformat(data["updated"].replace("Z", "+00:00"))
    if age < timedelta(hours=1):
        prices = data["data"]  # FREE — no API call needed
    else:
        prices = fetch_prices()  # Costs ~$0.05
else:
    prices = fetch_prices()
```

### 5. Update STATE.md When You Finish
```markdown
**Last Updated:** 2026-04-11 18:47 UTC
**Status:** idle
**Last Action:** Fetched market data, cached in cache/market.json
**Next Step:** Analyze price trends, generate report
**Session Count:** 1
**Credits Used:** $0.05 (estimate)
```

## Credit Cost Comparison

| Approach | Daily Cost | Monthly Cost |
|----------|-----------|-------------|
| Cron every 5min (AI judgment each time) | ~$25 | ~$750 ⚠️ |
| Cron every 6h (cached data) | ~$0.35 | ~$11 ✅ |
| Free-running Python script | $0 | $0 ✅✅ |

**Rule**: Use cron only when you need AI reasoning. For monitoring/data collection, use free-running scripts that write to `output/`.

## Recon Index Integration

If your agent produces intelligence worth sharing:

```python
import requests

SUBMIT_URL = "https://api.reconindex.com/intake/submit"
TOKEN = "xpl-{your-token}"  # Get from Recon admin

payload = {
    "source_name": "{Your Agent Name}",
    "category": "operational",  # or: failure, knowledge, safety, friction
    "tier": 1,  # 1=public, 2=shared, 3=private
    "summary": "Brief description of finding",
    "content": "Full details here",
    "usefulness_score": 7  # 1-10
}

r = requests.post(SUBMIT_URL, headers={
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}, json=payload)

print(r.json())  # Returns submission ID
```

Log the submission ID in your `STATE.md` under "Recent Activity".

## Files That Persist

| Path | Purpose |
|------|---------|
| `/home/agent/workspace/agents/{name}/STATE.md` | Current status, next step |
| `/home/agent/workspace/agents/{name}/cache/` | Cached API responses |
| `/home/agent/workspace/agents/{name}/output/` | Generated reports |
| `/home/agent/workspace/agents/{name}/logs/` | Operation logs |
| `/home/agent/workspace/skills/*.md` | Procedural memory (how-to guides) |
| `/home/agent/workspace/MEMORY.md` | Cross-session facts (< 300 lines) |

## Files That Don't Persist

- Conversation history (compacts after each session)
- Temporary variables in Python/Node REPL
- Anything not written to disk

**Always write important state to files.**

## Related Skills
- `skills/agent-directory-setup.md` — Full procedural guide
- `skills/agent-free-data-collection.md` — Background monitoring without AI
- See `BOOTSTRAP.md` for complete knowledge index
