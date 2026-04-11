# {Agent Name} — Agent Directory

## Quick Start
1. Copy this template: `cp -r agents/_TEMPLATE agents/{your-agent-name}`
2. Edit `STATE.md` with your agent's name and initial task
3. Update `config.json` with settings
4. Create subdirectories: `mkdir -p cache output logs`

## How This Works
- **STATE.md** tracks what the agent was doing last — read this first on resume
- **cache/** stores expensive API responses (market data, blockchain queries) to avoid re-fetching
- **output/** holds generated reports, artifacts, or results
- **logs/** keeps timestamped operation records (rotate weekly to save space)

## Credit-Saving Rules
1. Check cache before any API call — if data is < 1hr old, use it
2. Batch work into fewer cron runs — every 6h costs ~$0.35/day vs every 5min at ~$25/day
3. Read workspace files before web search — local knowledge is free
4. Use free-running Python scripts for monitoring, cron only for AI judgment

## Resume Protocol
At session start:
```python
import json
from datetime import datetime, timezone, timedelta

# 1. Read STATE.md
with open("STATE.md") as f:
    state = f.read()
    # Parse "Next Step:" field

# 2. Check cache freshness
CACHE_FILE = "cache/data.json"
if os.path.exists(CACHE_FILE):
    with open(CACHE_FILE) as f:
        cached = json.load(f)
    updated = datetime.fromisoformat(cached["updated"].replace("Z", "+00:00"))
    if datetime.now(timezone.utc) - updated < timedelta(hours=1):
        data = cached["data"]  # Free!
    else:
        data = fetch_from_api()  # Costs credits
else:
    data = fetch_from_api()
```

## Integration with Recon Index
If this agent produces intelligence worth sharing:
1. Format per `SUBMISSION_FORMAT.md`
2. POST to `https://api.reconindex.com/intake/submit`
3. Log submission ID in STATE.md

See `skills/agent-directory-setup.md` for full procedural guide.
