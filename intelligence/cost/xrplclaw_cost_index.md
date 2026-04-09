# XRPLClaw Cost Index
> Generated: 2026-04-09 | Unit: RLUSD (≈ $1 USD) | Source: platform docs + TOOLS.md

This index covers every cost-generating interaction on XRPLClaw, plus free runtime patterns and XRPL chain fees.  
Use it to budget before you build, not after.

---

## 1. AI Message Costs

Every message to your agent costs credits. Cost scales with:
- **Model mode** (Standard ~10× cheaper than Expert)
- **Context size** (longer conversations = more tokens re-read each turn)
- **Response complexity** (a table of data costs more than "yes")

### Estimated Cost Per Message

| Message Type | Standard Mode | Expert Mode |
|---|---|---|
| Short (1–2 sentences in, 1–2 sentences out) | ~$0.002 | ~$0.02 |
| Medium (paragraph in, structured reply out) | ~$0.008 | ~$0.08 |
| Long (complex request + tool calls + code) | ~$0.02–0.05 | ~$0.20–0.50 |
| Very long (multi-step build, research task) | ~$0.05–0.15 | ~$0.50–1.50 |

> These are estimates. Actual cost depends on token counts at billing time.

### Context Accumulation Effect

Each message re-reads the full conversation history. A 50-message thread might cost 3× more per message than a fresh session:

| Conversation Length | Relative Cost Multiplier |
|---|---|
| 1–10 messages | 1× (baseline) |
| 10–30 messages | 1.5–2× |
| 30–60 messages | 2–3× |
| 60+ messages | 3–5× |

**Best practice:** Start a new session when switching topics. Keep focused sessions short.

### Cache Hits vs Fresh Context

Auto-loaded workspace files (SOUL.md, AGENTS.md, USER.md, TOOLS.md) are cached by the platform. They cost far less to re-read than fresh web fetches or large files loaded for the first time. Knowledge files read on-demand (`knowledge_read`) are cheaper than re-explaining context in chat.

### Daily Cost by Usage Intensity

| Intensity | Pattern | Approx Daily Cost |
|---|---|---|
| Light | 5 messages, Standard mode, short sessions | ~$0.05 |
| Moderate | 20 messages, mix of Standard/Expert | ~$0.50–1.00 |
| Heavy | 50 messages, mostly Expert, long sessions | ~$3.00–8.00 |
| Very heavy | 100+ messages, Expert, complex tasks | ~$10–25 |

---

## 2. Cron Job Costs

**Every cron execution = a new isolated agent session.** Context is minimal (only auto-loaded files), but the session startup + task execution still burns credits.

### Cost Per Cron Execution

| Mode | Estimated Cost Per Run |
|---|---|
| Standard mode, simple task | ~$0.05–0.09 |
| Expert mode, simple task | ~$0.09–0.15 |
| Expert mode, complex judgment | ~$0.15–0.50 |

> The $0.09/day figure in TOOLS.md reflects a minimal Standard-mode daily cron.

### Frequency Cost Table

| Frequency | Runs/Day | Runs/Month | ~Monthly Cost (Standard) | ~Monthly Cost (Expert) |
|---|---|---|---|---|
| Every 5 min | 288 | 8,640 | ~$750 | ~$1,300+ |
| Every 15 min | 96 | 2,880 | ~$250 | ~$430 |
| Every 30 min | 48 | 1,440 | ~$125 | ~$215 |
| Every hour | 24 | 720 | ~$60 | ~$108 |
| Every 6 hours | 4 | 120 | ~$10 | ~$18 |
| Every 12 hours | 2 | 60 | ~$5 | ~$9 |
| Once daily | 1 | 30 | ~$2.70 | ~$4.50 |
| Once weekly | 0.14 | 4 | ~$0.36 | ~$0.60 |

### Real Cron Examples

| Use Case | Recommended Frequency | Mode | Est. Monthly Cost |
|---|---|---|---|
| XRP price monitor + Telegram alert | Every 6h (Python monitors, cron only fires on signal) | Standard | ~$10 |
| Trading signal check + journal entry | Once daily | Expert | ~$4.50 |
| Portfolio rebalance decision | Once daily | Expert | ~$4.50 |
| NFT floor sweep alert | Every hour | Standard | ~$60 |
| News sentiment + brief | Once daily | Expert | ~$4.50 |

### Minimizing Cron Cost

1. **Use Python for monitoring, cron for judgment.** A Python loop checking prices costs $0 in AI credits. Only invoke the agent when a threshold is crossed.
2. **Keep cron prompts short.** Less context = faster, cheaper execution.
3. **Use Standard mode** unless the cron task needs multi-step reasoning or code generation.
4. **Daily or 6-hourly is almost always enough.** Rarely does AI judgment need to run every 5 minutes.
5. **Pass only what's needed.** Write the relevant data to a file, then pass the file path — not raw data dumps.

---

## 3. Build Costs (One-Time)

These are estimates for the full AI conversation needed to design, build, test, and deliver a working system.

| Build Type | Approx. One-Time Cost | Notes |
|---|---|---|
| Simple script (price fetch, trustline, send XRP) | ~$0.10–0.30 | 2–5 message exchange |
| Telegram bot with commands | ~$0.50–1.50 | Setup + coding + testing iterations |
| Web dashboard (HTML/JS, Cloudflare Pages) | ~$1.00–3.00 | Design + code + deploy + polish |
| Trading bot with strategy logic | ~$2.00–5.00 | Strategy + backtest + bot + monitoring |
| Multi-process system (monitor + bot + alerts) | ~$3.00–8.00 | Architecture discussion + build phases |
| XRPL Hooks / smart contract | ~$5.00–15.00 | Complex — requires Hooks knowledge + iteration |
| Full multi-agent system (Walkie P2P, coordination) | ~$8.00–20.00 | Architecture + spawning + inter-agent protocol |

> Costs rise with clarification rounds. Clear specs = cheaper builds. Reusing workspace files slashes cost on rebuild.

---

## 4. Runtime Costs (After Build)

Once built, most automation runs **free** — no AI credits consumed.

| Component | Cost | Notes |
|---|---|---|
| Background Python process | **FREE** | No agent session — pure compute |
| Background Node.js process | **FREE** | Same as Python |
| Bash scripts (crontab, exec) | **FREE** | No AI tokens |
| Cloudflare quick tunnel | **FREE** | Temporary HTTPS URL |
| Cloudflare Pages deploy | **FREE** | Persistent hosting, custom domain optional |
| Web server from workspace | **FREE** | Served via tunnel or Pages |
| Walkie P2P agent messaging | **FREE** | Encrypted, no AI credits |
| XRPL MCP tool calls (read) | **FREE** | Built-in blockchain queries |
| XRPL transactions (write) | **Separate — XRP drops** | See Section 5 |
| Cron execution | **~$0.05–0.50/run** | Each run = new AI session |

**Key insight:** The best automation pattern on XRPLClaw is: Python does the work (free), cron just reports (cheap).

---

## 5. XRPL Transaction Costs (Separate from XRPLClaw Credits)

XRPL fees are paid in XRP from your wallet — not from XRPLClaw credits.

| Operation | Cost | Notes |
|---|---|---|
| Base transaction fee | 10–12 drops XRP (~$0.00001) | Standard for most transactions |
| Account creation (reserve) | 10 XRP (~$2.50) | One-time, locked as reserve |
| Trustline creation (reserve) | 2 XRP per line (~$0.50) | Locked while trustline open |
| DEX offer placement | ~10–12 drops + reserve if new | Reserve per open offer |
| AMM deposit / withdrawal | ~10–12 drops | Base fee; no reserve lock |
| AMM pool creation | ~10–12 drops + 2 XRP reserve | Reserve for AMM account object |
| NFT mint | ~10–12 drops | +2 XRP reserve per new NFT page |
| NFT offer creation | ~10–12 drops | Reserve per offer object |
| Payment (XRP or IOU) | ~10–12 drops | Cheapest operation |
| Escrow create/finish/cancel | ~10–12 drops each | Per operation |
| Hook set / invoke | ~10–12 drops base | Higher for complex Hooks |

> XRP price at time of writing: ~$0.25–0.50. Reserves are recoverable when objects are deleted.

---

## 6. Cost Optimization Patterns

### Use Standard Mode For:
- Quick questions and lookups
- Single-step tasks (send XRP, check balance, price check)
- Generating short scripts you already understand
- Cron jobs with routine outputs
- Answering "what is X" questions
- Any task that doesn't require multi-step reasoning

### Use Expert Mode For:
- Debugging complex logic or errors
- Designing system architecture
- Writing trading strategy code from scratch
- Multi-agent coordination design
- Research + synthesis tasks
- Hooks / smart contract code
- Tasks where first-attempt quality matters (saves iteration cost)

### Use Free Background Processes Instead of Cron For:
- Price monitoring (run a Python loop, write alerts to a file)
- WebSocket subscriptions (XRPL ledger events)
- Log tailing and threshold detection
- Continuous data collection (OHLCV, order book depth)
- Anything that just needs to check a condition repeatedly

### One-Time Build vs Recurring Cron Decision Framework

```
Does this task need AI judgment each time?
├── NO → Build it once as a script, run it free
│         (monitoring, data collection, alerts via webhook/Telegram directly)
└── YES → Does it need judgment more than once daily?
          ├── NO → Daily or weekly cron is probably fine
          └── YES → Are you sure AI is needed, or just logic?
                    ├── Just logic → Script it (free)
                    └── Actually AI → Hourly at most; Standard mode
```

### Conversation Hygiene

- **Start fresh sessions** when switching between unrelated topics
- **Don't re-explain context** that's in workspace files — Recon reads them automatically
- **Avoid pasting large data blobs** in chat — write to a file and reference it instead
- **Keep builds sequential** — finish one thing before starting another in the same session
- **Break very complex projects into phases** — each phase as its own session

---

## 7. Cost Traps to Avoid

| Trap | Impact | Fix |
|---|---|---|
| **Expert mode left on for simple tasks** | 10× cost for same output | Switch to Standard for Q&A, lookups, simple scripts |
| **High-frequency crons for non-AI tasks** | $25–750/month for monitoring that could be free | Use Python loops; cron only for AI judgment |
| **Long conversations that balloon context** | Cost per message doubles or triples | Start new sessions when switching topics |
| **Rebuilding from scratch** | Full build cost again | Reference workspace files; Recon remembers prior work |
| **Asking Recon to monitor prices in chat** | Keeps a session alive; expensive | Use a cron job or background script instead |
| **Pasting raw API responses into chat** | Adds tokens for context you already have | Write to file, pass path reference |
| **Using cron for tasks that run in milliseconds** | Agent session overhead >> task time | Script it and run via exec or crontab (not OpenClaw cron) |
| **Multiple crons for related tasks** | Compounds session cost | Consolidate related checks into one cron |

---

## 8. Example Monthly Cost Scenarios

### Casual User
- 5 messages/day (Standard mode, short sessions)
- 1 daily cron (Standard, simple task)
- No automation builds

| Item | Daily | Monthly |
|---|---|---|
| Messages (5 × $0.004 avg) | $0.02 | ~$0.60 |
| Daily cron | $0.09 | ~$2.70 |
| **Total** | **$0.11** | **~$3.30** |

---

### Active Builder
- 20 messages/day (mix Standard/Expert)
- 2–3 build projects per month (~$3 each)
- 1 hourly cron (Standard mode)
- No heavy automation

| Item | Daily | Monthly |
|---|---|---|
| Messages (20 × $0.025 avg) | $0.50 | ~$15 |
| Builds (2–3 projects) | — | ~$6–9 |
| Hourly cron (Standard) | $2.00 | ~$60 |
| **Total** | — | **~$80–85** |

> **Note:** The hourly cron dominates. Dropping to 6-hourly saves ~$50/month.

---

### Power User
- 50 messages/day (Expert-heavy, complex sessions)
- 1 daily AI cron (Expert)
- 1 Python trading monitor (free)
- 1 hourly Standard cron for portfolio snapshot

| Item | Daily | Monthly |
|---|---|---|
| Messages (50 × $0.08 avg) | $4.00 | ~$120 |
| Daily Expert cron | $0.15 | ~$4.50 |
| Hourly Standard cron | $2.00 | ~$60 |
| **Total** | **$6.15** | **~$185** |

---

### Heavy Automation
- 100+ messages/day (Expert mode, long sessions)
- Multiple crons: hourly (×2) + 6-hourly (×2) + daily (×3)
- Several active builds in progress

| Item | Daily | Monthly |
|---|---|---|
| Messages (100 × $0.10 avg) | $10 | ~$300 |
| Hourly crons ×2 (Standard) | $4.00 | ~$120 |
| 6-hourly crons ×2 (Standard) | $0.70 | ~$21 |
| Daily crons ×3 (Expert) | $0.45 | ~$13.50 |
| Builds (active) | — | ~$20 |
| **Total** | **~$15** | **~$475** |

> At this level, ruthless cron hygiene is critical. Shifting hourly crons to 6-hourly saves ~$100/month alone.

---

## Quick Reference Card

```
Standard mode:   ~$0.002–0.05/msg
Expert mode:     ~$0.02–1.50/msg
Daily cron:      ~$0.09–0.15/run
Hourly cron:     ~$2.00/day
5-min cron:      ~$25/day = ~$750/month ⚠️
Python process:  FREE
Cloudflare:      FREE
XRPL base fee:   0.00001 XRP (~$0.000005)
XRPL reserve:    10 XRP base + 2 XRP/object
```

---

*Last updated: 2026-04-09. Costs are estimates based on platform documentation. Actual billing depends on token counts.*
