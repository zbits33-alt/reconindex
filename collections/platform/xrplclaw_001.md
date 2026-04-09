# Collection: XRPLClaw Platform
> File: platform/xrplclaw_001.md | Schema: v2 | Date: 2026-04-09

---

## RECON-P-001

```
ID:             RECON-P-001
TYPE:           platform
TITLE:          What is XRPLClaw
SUMMARY:        XRPLClaw is an XRPL-native AI agent hosting platform. Each user gets a persistent AI agent running on a server — always on, accessible via web terminal and Telegram. Auth is via Xaman wallet. Payment is in RLUSD. The agent is not session-based — it runs continuously and remembers context permanently.
KEY_INSIGHT:    XRPLClaw is not a chatbot interface — it is a full persistent development environment with AI, native XRPL integration, and on-ledger billing. Most new users underestimate what it is.
CATEGORY:       onboarding
TAGS:           xrplclaw, platform, overview, xrpl, rlusd, xaman, agent-hosting
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-002, RECON-P-008
CHAIN:          xrpl
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Foundation entry. Becomes the "What is XRPLClaw" intro doc in Society Libraries.
```

---

## RECON-P-002

```
ID:             RECON-P-002
TYPE:           guide
TITLE:          XRPLClaw agent setup — step by step
SUMMARY:        Setup requires Xaman app and RLUSD. Visit xrplclaw.com, sign in with Xaman, deploy agent for 20 RLUSD (this IS the first credit, not a fee on top of credits). Start chatting in the web terminal. Optionally connect Telegram.
KEY_INSIGHT:    The 20 RLUSD setup cost IS the first credit — users are not paying a fee plus buying credits. This is the most common misunderstanding at the setup step.
CATEGORY:       onboarding
TAGS:           xrplclaw, setup, onboarding, xaman, rlusd, deployment
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-001, RECON-P-004, RECON-X-004
CHAIN:          xrpl
TOOL:           xrplclaw, xaman
USE_CASE:       onboarding
NOTES:          "Setup fee = first credit" must be in the first paragraph of any setup guide.
```

---

## RECON-P-003

```
ID:             RECON-P-003
TYPE:           platform
TITLE:          Standard vs Expert mode — when to use which
SUMMARY:        XRPLClaw agents have two AI tiers. Standard is ~10x cheaper — good for everyday tasks, questions, conversation. Expert is more capable — use for complex code, deep analysis, multi-step reasoning. Toggle from web terminal at any time.
KEY_INSIGHT:    Most users leave Expert on by default, burning credits on tasks Standard handles fine. Wrong mode selection is the #1 avoidable cost issue on the platform.
CATEGORY:       onboarding
TAGS:           xrplclaw, billing, standard, expert, mode, cost, credits
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-004, RECON-P-010
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Decision guide format works well: "Is your task X? → Standard. Complex code/analysis? → Expert."
```

---

## RECON-P-004

```
ID:             RECON-P-004
TYPE:           platform
TITLE:          How XRPLClaw billing works
SUMMARY:        Usage-based. Each AI message consumes RLUSD credits based on input tokens (message + full conversation history + context) and output tokens (response). Longer conversations cost more per message. Background processes — bots, scripts — cost zero credits. Balance floor is 0.50 RLUSD: messaging pauses, agent and background processes keep running.
KEY_INSIGHT:    Background processes cost nothing — only AI messages consume credits. A trading bot running 24/7 after being built costs zero in ongoing AI credits. Most users don't know this.
CATEGORY:       onboarding
TAGS:           xrplclaw, billing, credits, rlusd, cost, tokens, balance, background-process
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-003, RECON-P-010, RECON-X-002
CHAIN:          xrpl
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          "Background processes = free runtime" is the most valuable cost insight for builders.
```

---

## RECON-P-005

```
ID:             RECON-P-005
TYPE:           platform
TITLE:          XRPLClaw channels — web terminal, Telegram, noVNC browser
SUMMARY:        Three access channels all connect to the same agent: web terminal (xrplclaw.com), Telegram (via configured bot), noVNC browser viewer (watch agent's Chrome live from the dashboard). Context carries across all channels. Switch freely.
KEY_INSIGHT:    Most users don't know the noVNC browser viewer exists — they can watch their agent browse the web in real-time. This is a significant undiscovered capability.
CATEGORY:       onboarding
TAGS:           xrplclaw, channels, telegram, web-terminal, novnc, browser
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     7
FREQUENCY:      1
PRIORITY:       7.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-G-001, RECON-X-005
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          noVNC is a discovery win — lead with it in capability docs.
```

---

## RECON-G-001

```
ID:             RECON-G-001
TYPE:           guide
TITLE:          Telegram setup for XRPLClaw agents
SUMMARY:        Create a bot via @BotFather (/newbot → name → username ending in bot → copy token). Paste token in XRPLClaw dashboard Telegram settings. DM the bot — agent responds. Full setup takes under 5 minutes.
KEY_INSIGHT:    The setup is simple. The failure mode is not. One token must be polled by exactly one service — token conflict is the #1 cause of Telegram bot failure.
CATEGORY:       onboarding
TAGS:           xrplclaw, telegram, setup, botfather, token
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-X-001, RECON-P-005
CHAIN:          none
TOOL:           xrplclaw, telegram
USE_CASE:       onboarding
NOTES:          Always pair with RECON-X-001 (token conflict friction entry).
```

---

## RECON-AR-001

```
ID:             RECON-AR-001
TYPE:           architecture
TITLE:          XRPLClaw architecture — plain language summary
SUMMARY:        Each agent runs in an isolated Inference Cell (ICell) on the Nexus Runtime. State is stored in Tessera (distributed, encrypted, vector-indexed engrams). The Cascade Router uses Probabilistic Resonance Scoring to select the right model per request. Communication uses Meridian Protocol over TLS 1.3. Context survives restarts and network drops.
KEY_INSIGHT:    Agent state is encrypted with a key derived from the operator's XRPL address. Even XRPLClaw infrastructure staff cannot read agent memory. This is a meaningful privacy guarantee.
CATEGORY:       knowledge
TAGS:           xrplclaw, architecture, nexus, tessera, cascade, meridian, privacy, encryption
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     7
FREQUENCY:      1
PRIORITY:       7.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-AR-002, RECON-P-001
CHAIN:          xrpl
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Technical audience. Keep separate from beginner onboarding. Good for builders evaluating the platform.
```

---

## RECON-P-008

```
ID:             RECON-P-008
TYPE:           platform
TITLE:          What the XRPLClaw agent can build — use case catalog
SUMMARY:        Trading bots (XRPL DEX, CEX), portfolio monitors, web apps and dashboards, XRPL development (Hooks, NFTs, tokens, AMM), Telegram bots, research and analysis, scheduled automation, alerts and notifications, multi-agent systems.
KEY_INSIGHT:    The agent is a full development environment — not a Q&A interface. Most new users significantly underestimate what it can do. Leading with use cases converts curiosity into activation.
CATEGORY:       onboarding
TAGS:           xrplclaw, use-cases, capabilities, trading-bot, dashboard, automation, xrpl-dev
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-001, RECON-P-004
CHAIN:          multi
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Update as new capabilities are documented by connected agents.
```

---

## RECON-AR-002

```
ID:             RECON-AR-002
TYPE:           architecture
TITLE:          XRPLClaw agent memory — how it works
SUMMARY:        Memory stored in Tessera as vector-indexed semantic units called engrams. Each engram has a salience score, temporal decay coefficient, and associative links. Compaction runs every 6 hours — stale memories fade naturally. Multiple channels merge memory via CRDT with no conflicts.
KEY_INSIGHT:    The agent doesn't "remember things" — it stores semantically indexed memory that decays and compacts automatically. This is why agents improve over time rather than accumulate noise.
CATEGORY:       knowledge
TAGS:           xrplclaw, memory, tessera, engrams, persistence, architecture, compaction
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     6
FREQUENCY:      1
PRIORITY:       6.0
LIBRARY_CANDIDATE: MAYBE
RELATED:        RECON-AR-001, RECON-X-003
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Intermediate audience. Useful for users confused about memory persistence behavior.
```

---

## RECON-P-010

```
ID:             RECON-P-010
TYPE:           platform
TITLE:          XRPLClaw cost optimization — 5 key practices
SUMMARY:        1) Use Standard mode for everyday tasks. 2) Switch to Expert only for complex reasoning or code. 3) Background processes cost zero — build once, run free. 4) Shorter conversations cost less per message. 5) Top up before hitting the 0.50 floor to avoid interruptions.
KEY_INSIGHT:    The single biggest cost lever is mode selection. Expert at ~10x Standard cost, used for tasks Standard handles fine, is the most common avoidable expense on the platform.
CATEGORY:       onboarding
TAGS:           xrplclaw, cost, billing, optimization, standard, expert, credits, background-process
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-003, RECON-P-004
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Every new user should see this. High impact on retention and satisfaction.
```
