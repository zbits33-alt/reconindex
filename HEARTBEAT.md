# Heartbeat — Periodic Checks

Run these checks when the heartbeat triggers.

## Checklist

- [ ] **Memory maintenance**: If `MEMORY.md` exceeds 300 lines, distill — remove outdated entries, compress verbose ones, keep it lean.
- [ ] **Skills review**: Scan `skills/` for outdated or incomplete procedures. Patch or remove stale skills.
- [ ] **Daily log cleanup**: If daily log files in `memory/` are older than 7 days, archive key insights to `MEMORY.md` and delete the logs.
- [ ] **Workspace hygiene**: Check for stale temp files, scratch scripts, or old outputs. Clean up.
- [ ] **Market data freshness**: Check `state/market/briefing.md` — if the "Updated" timestamp is older than 10 minutes, note it in your next response to the operator. Check `state/market/briefing.json` → `meta.errors` for any degraded data sources.
- [ ] **Session cleanup**: Count `.jsonl` files in `~/.openclaw/agents/main/sessions/`. If more than 5, delete all except the current session's file.
