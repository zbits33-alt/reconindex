# Collection: XRPLClaw Cost Index
> File: platform/xrplclaw_costs_001.md | Schema: v2 | Date: 2026-04-09
> Reference: intelligence/cost/xrplclaw_cost_index.md

---

## RECON-P-011

```
ID:             RECON-P-011
TYPE:           platform
TITLE:          XRPLClaw AI Message Costs — Standard vs Expert mode
SUMMARY:        Every agent message costs RLUSD credits. Standard mode costs ~10x less than Expert. Short messages in Standard mode cost ~$0.002; long Expert sessions can cost $0.50–1.50 per message. Context accumulation means messages in long threads cost 2–5x more than fresh sessions. Cache hits on workspace files reduce cost significantly.
KEY_INSIGHT:    Standard mode is 10x cheaper than Expert for the same task. Switching modes and keeping sessions focused are the two highest-leverage cost controls an operator has.
CATEGORY:       operational
TAGS:           xrplclaw, credits, rlusd, cost, standard-mode, expert-mode, tokens, context
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-012, RECON-P-016, RECON-P-017
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Most impactful cost knowledge for new users. Pair with mode-switching guidance.
```

---

## RECON-P-012

```
ID:             RECON-P-012
TYPE:           platform
TITLE:          XRPLClaw Cron Job Costs — Frequency vs Credit Burn
SUMMARY:        Every cron execution starts a new isolated agent session, costing $0.05–0.50 per run depending on mode and task complexity. A 5-minute cron costs ~$25/day ($750/month). A daily cron costs ~$0.09/day ($2.70/month). Frequency selection is the most consequential cron cost decision. Standard mode + simple prompts keeps per-run cost near the minimum.
KEY_INSIGHT:    Cron frequency is the single biggest cost lever on the platform. Every step up in frequency multiplies monthly cost by the same factor. A 5-minute cron costs 288x more per day than a daily cron.
CATEGORY:       operational
TAGS:           xrplclaw, cron, credits, rlusd, automation, cost, frequency, scheduling
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     10
FREQUENCY:      1
PRIORITY:       10.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-011, RECON-P-014, RECON-P-016, RECON-P-017
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       automation
NOTES:          Highest usefulness entry — cron cost misunderstanding is the #1 source of runaway spend. Frequency table in cost index is key reference.
```

---

## RECON-P-013

```
ID:             RECON-P-013
TYPE:           guide
TITLE:          XRPLClaw Build Costs — One-Time AI Conversation Estimates
SUMMARY:        Building things on XRPLClaw has a one-time AI conversation cost. Simple scripts cost $0.10–0.30. A full web dashboard costs $1–3. A trading bot with strategy logic costs $2–5. A full multi-agent system can cost $8–20 in build conversation credits. Clear specs and reusing workspace files reduce build cost significantly.
KEY_INSIGHT:    Build costs are one-time and generally low ($0.10–$20). The ongoing automation costs (cron, messages) almost always dominate total spend. Build something good once and run it free.
CATEGORY:       build
TAGS:           xrplclaw, build, cost, rlusd, scripts, bots, dashboards, trading-bot, hooks
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-011, RECON-P-014, RECON-P-016
CHAIN:          xrpl
TOOL:           xrplclaw
USE_CASE:       development
NOTES:          Useful for pre-project budgeting. Pair with runtime cost entry (P-014) to give full picture.
```

---

## RECON-P-014

```
ID:             RECON-P-014
TYPE:           platform
TITLE:          XRPLClaw Runtime Costs — What Runs Free After Build
SUMMARY:        After a project is built, most automation runs at zero AI credit cost. Background Python/Node processes, Cloudflare tunnels, Cloudflare Pages deployments, Walkie P2P agent messaging, and XRPL MCP read queries are all free. Only cron jobs (AI sessions) and XRPL write transactions consume credits or XRP respectively.
KEY_INSIGHT:    The best XRPLClaw automation pattern is: Python/Node does the work for free, cron only invokes AI when judgment is needed. This can reduce ongoing costs by 10–100x vs naive cron-for-everything approaches.
CATEGORY:       operational
TAGS:           xrplclaw, runtime, free, background-process, cloudflare, walkie, cost, python, node
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-012, RECON-P-013, RECON-P-016
CHAIN:          none
TOOL:           xrplclaw, cloudflare
USE_CASE:       automation
NOTES:          This pattern is the core cost-efficiency unlock for builders. Critical to surface early.
```

---

## RECON-P-015

```
ID:             RECON-P-015
TYPE:           platform
TITLE:          XRPL Transaction Costs — Separate from XRPLClaw Credits
SUMMARY:        XRPL blockchain fees are paid in XRP from the operator's wallet, not from XRPLClaw credits. Base transaction fee is 10–12 drops (~$0.00001). Account creation requires 10 XRP reserve (~$2.50). Each trustline locks 2 XRP. NFT pages, open offers, and AMM objects each carry reserve requirements. Reserves are recoverable when objects are deleted.
KEY_INSIGHT:    XRPL on-chain costs are nearly free for operations (sub-cent), but reserves (10 XRP base + 2 XRP/object) can add up when building token systems or maintaining many open offers. Always budget for reserves, not just fees.
CATEGORY:       operational
TAGS:           xrpl, fees, reserves, drops, trustline, nft, amm, dex, transaction-cost
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-011, RECON-P-014
CHAIN:          xrpl
TOOL:           xrplclaw
USE_CASE:       development
NOTES:          Operators often forget reserves. Particularly important for token launch projects.
```

---

## RECON-P-016

```
ID:             RECON-P-016
TYPE:           guide
TITLE:          XRPLClaw Cost Optimization Patterns — Mode, Cron, and Process Selection
SUMMARY:        Key optimization patterns: use Standard mode for lookups and simple tasks; Expert mode only for complex reasoning or architecture work. Replace high-frequency crons with free Python background loops. Start fresh sessions when switching topics. Pass file paths instead of raw data dumps in chat. Consolidate related crons into single sessions.
KEY_INSIGHT:    The three highest-leverage cost controls are: (1) mode selection, (2) cron frequency, (3) conversation hygiene. Together they can reduce monthly spend by 5–20x without reducing capability.
CATEGORY:       operational
TAGS:           xrplclaw, optimization, cost, standard-mode, expert-mode, cron, conversation, hygiene
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-011, RECON-P-012, RECON-P-014, RECON-P-017
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Should appear early in any cost guide or onboarding flow for builders.
```

---

## RECON-P-017

```
ID:             RECON-P-017
TYPE:           failure
TITLE:          XRPLClaw Cost Traps — Common Patterns That Waste Credits
SUMMARY:        Common cost traps: Expert mode left on for simple Q&A (10x overspend), high-frequency crons for tasks that could be free Python scripts, long sprawling sessions that triple context cost, rebuilding from scratch instead of referencing workspace files, pasting large data blobs into chat instead of file references. Each trap can 2–10x monthly spend with no benefit.
KEY_INSIGHT:    The most common cost mistake is a 5-minute cron for a monitoring task that could be a free Python loop. Second most common: Expert mode left on during casual use. Both are easy to fix once identified.
CATEGORY:       failure
TAGS:           xrplclaw, cost-trap, waste, expert-mode, cron, context, rebuild, optimization
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-011, RECON-P-012, RECON-P-016
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Anti-pattern entry. High value for retention — operators who hit these traps churn.
```

---

## RECON-P-018

```
ID:             RECON-P-018
TYPE:           guide
TITLE:          XRPLClaw Monthly Cost Scenarios — Casual to Heavy Automation
SUMMARY:        Four reference scenarios: Casual user (5 msg/day + 1 daily cron) ~$3.30/month. Active builder (20 msg/day + hourly cron + builds) ~$80–85/month — hourly cron dominates. Power user (50 Expert msg/day + multiple crons) ~$185/month. Heavy automation (100+ msg + multiple crons + active builds) ~$475/month. Cron frequency is the dominant cost driver at all levels above casual.
KEY_INSIGHT:    For most builders, the monthly cost is dominated by cron frequency, not messages. An active builder can cut their bill in half by dropping from hourly to 6-hourly crons — with almost no loss of utility for most tasks.
CATEGORY:       operational
TAGS:           xrplclaw, monthly-cost, budget, scenarios, casual, builder, power-user, automation
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-011, RECON-P-012, RECON-P-016, RECON-P-017
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Reference scenarios are useful for sales/onboarding conversations and self-service budgeting.
```
