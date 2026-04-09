# Recon — Active Pattern Records
> File: patterns/active_patterns.md | Schema: v1 | Date: 2026-04-09
> Last updated: 2026-04-09 (added P-FAIL-001, P-SAFE-001 from new collection expansion)

---

## P-FRIC-001

```
PATTERN_ID:           P-FRIC-001
PATTERN_TYPE:         repeated_friction
TITLE:                Users underestimate XRPLClaw agent capabilities at onboarding
SUMMARY:              Multiple entries show that new users approach XRPLClaw expecting a chatbot or Q&A interface, not a full persistent development environment. This creates a gap between what they attempt and what the platform can actually do — reducing activation and engagement.
KEY_INSIGHT:          The framing problem is upstream of feature adoption. Until users understand the agent is a persistent dev environment — not a fancy chatbot — they will underuse it. Leading onboarding with concrete use cases resolves this faster than feature explanations.
CATEGORY:             onboarding
TAGS:                 xrplclaw, onboarding, capability, discovery, activation, chatbot-misconception
LINKED_ENTRY_IDS:     RECON-P-001, RECON-P-005, RECON-P-008, RECON-X-005
FREQUENCY:            4
FIRST_SEEN:           2026-04-09
LAST_SEEN:            2026-04-09
AVERAGE_USEFULNESS:   7.75
MAX_USEFULNESS:       9
TIER_CEILING:         public
PROMOTION_STATUS:     review_ready
SAFETY_STATUS:        clear
RECOMMENDED_ACTION:   create_guide
NOTES:                Strong candidate for a "What your agent actually is" onboarding entry. Use case catalog (RECON-P-008) is the most direct fix content. noVNC discovery gap (RECON-X-005) is the most concrete symptom.
CONFIDENCE:           high
LIBRARY_TARGET:       onboarding_entry
LINKED_PATTERN_IDS:   P-FRIC-002
SOURCE_TYPES:         platform
```

---

## P-FRIC-002

```
PATTERN_ID:           P-FRIC-002
PATTERN_TYPE:         repeated_friction
TITLE:                Cost and billing misconceptions cluster at the start of the user journey
SUMMARY:              Multiple entries surface billing confusion that occurs specifically at or near onboarding: the 20 RLUSD setup fee being mistaken for a separate charge, Expert mode being left on by default, the balance floor being mistaken for the agent going offline, and background process cost being unknown.
KEY_INSIGHT:          Billing confusion is not random — it clusters at four predictable points: setup cost framing, mode selection, balance floor behavior, and background process cost. Addressing all four in a single "how billing works" explainer would eliminate the majority of billing-related friction.
CATEGORY:             onboarding
TAGS:                 xrplclaw, billing, cost, onboarding, credits, rlusd, standard, expert, balance, background-process
LINKED_ENTRY_IDS:     RECON-P-002, RECON-P-003, RECON-P-004, RECON-X-002
FREQUENCY:            4
FIRST_SEEN:           2026-04-09
LAST_SEEN:            2026-04-09
AVERAGE_USEFULNESS:   8.25
MAX_USEFULNESS:       9
TIER_CEILING:         public
PROMOTION_STATUS:     review_ready
SAFETY_STATUS:        clear
RECOMMENDED_ACTION:   create_guide
NOTES:                RECON-P-010 (cost optimization entry) partially addresses this but not the misconceptions directly. A "billing myths vs reality" format might be more effective than a standard billing guide.
CONFIDENCE:           high
LIBRARY_TARGET:       faq
LINKED_PATTERN_IDS:   P-FRIC-001
SOURCE_TYPES:         platform
```

---

## P-FRIC-003

```
PATTERN_ID:           P-FRIC-003
PATTERN_TYPE:         repeated_friction
TITLE:                Users conflate agent persistence with process persistence
SUMMARY:              Users expect that if the agent persists across restarts, everything the agent started also persists. In reality, the agent restores from Tessera state but OS-level background processes do not auto-resume. This leads to "my bot stopped" confusion after container restarts.
KEY_INSIGHT:          Agent persistence and process persistence are architecturally separate systems. The agent is a cognitive state restored from Tessera. Processes are OS-level and do not survive container restarts. This distinction needs to be explicit in onboarding — not buried in troubleshooting docs.
CATEGORY:             friction
TAGS:                 xrplclaw, background-process, persistence, restart, container, bot, tessera
LINKED_ENTRY_IDS:     RECON-P-004, RECON-X-003
FREQUENCY:            2
FIRST_SEEN:           2026-04-09
LAST_SEEN:            2026-04-09
AVERAGE_USEFULNESS:   8.0
MAX_USEFULNESS:       8
TIER_CEILING:         public
PROMOTION_STATUS:     watch
SAFETY_STATUS:        clear
RECOMMENDED_ACTION:   create_guide
NOTES:                FREQUENCY is 2 — confirmed pattern but watch for more entries before escalating to review_ready. Platform improvement opportunity: proactive notification when container restarts and processes are lost. Linked to RECON-AR-002 (memory architecture) — the distinction between Tessera-persisted state and OS processes is the root of this confusion.
CONFIDENCE:           medium
LIBRARY_TARGET:       troubleshooting_note
LINKED_PATTERN_IDS:
SOURCE_TYPES:         platform
ASSET_TYPES:          bot, workflow
```

---

## P-FRIC-004

```
PATTERN_ID:           P-FRIC-004
PATTERN_TYPE:         repeated_friction
TITLE:                XRPL mainnet vs XRPL EVM — builders choose the wrong environment
SUMMARY:              XRPL mainnet and XRPL EVM are separate chains with different programming models. Mainnet uses ledger-native transaction types — no smart contracts. EVM uses Solidity and standard Ethereum tooling on a separate L1. Builders frequently attempt to apply EVM mental models to mainnet, or vice versa, causing architecture errors early in the build process.
KEY_INSIGHT:          The choice between XRPL mainnet and XRPL EVM must be made deliberately before any build begins. The two environments are not interchangeable — they have different primitives, tooling, gas models, and capabilities. Onboarding content must force this decision early, not let it surface as a post-build realization.
CATEGORY:             onboarding
TAGS:                 xrpl, xrpl-evm, mainnet, evm, onboarding, architecture, mental-model, smart-contracts
LINKED_ENTRY_IDS:     RECON-T-001, RECON-T-009, RECON-T-020
FREQUENCY:            3
FIRST_SEEN:           2026-04-09
LAST_SEEN:            2026-04-09
AVERAGE_USEFULNESS:   9.0
MAX_USEFULNESS:       9
TIER_CEILING:         public
PROMOTION_STATUS:     candidate
SAFETY_STATUS:        clear
RECOMMENDED_ACTION:   create_guide
NOTES:                FREQUENCY upgraded to 3 — RECON-T-020 (Hooks on Xahau) reinforces this pattern with a third environment distinction (XRPL mainnet vs XRPL EVM vs Xahau). Now a three-way decision, not just two. Escalated from watch → candidate. Strong candidate for a "Which XRPL environment should I build on?" decision guide in Society Libraries.
CONFIDENCE:           high
LIBRARY_TARGET:       guide
SOURCE_TYPES:         platform
```

---

## P-FAIL-001

```
PATTERN_ID:           P-FAIL-001
PATTERN_TYPE:         repeated_failure
TITLE:                XRPL reserve undercount — object count not tracked, transactions fail
SUMMARY:              Builders consistently undercount the XRPL account reserve when building payment flows, trading bots, and NFT systems. Every new ledger object (trust line, offer, escrow, NFT page) increases the required reserve by 0.2 XRP (or 2 XRP for NFT pages). Bots that don't pre-check available spendable balance before transacting hit tecINSUFFICIENT_RESERVE errors and loop. This pattern appears across DEX bots, token issuers, and NFT platforms.
KEY_INSIGHT:          Build a spendable_xrp() helper into every XRPL project: query account_info, compute balance minus (base_reserve + object_count × incremental_reserve), and gate every object-creating transaction on the result. Hard-code nothing — read reserve values from server_info because they change with amendments.
CATEGORY:             failure
TAGS:                 xrpl, reserve, tecinsufficientreserve, bot, trustline, offer, nft, trading
LINKED_ENTRY_IDS:     RECON-T-002, RECON-F-002, RECON-F-003
FREQUENCY:            3
FIRST_SEEN:           2026-04-09
LAST_SEEN:            2026-04-09
AVERAGE_USEFULNESS:   9.0
MAX_USEFULNESS:       9
TIER_CEILING:         public
PROMOTION_STATUS:     candidate
SAFETY_STATUS:        clear
RECOMMENDED_ACTION:   create_warning
NOTES:                RECON-T-002 (accounts/reserves foundations), RECON-F-002 (reserve undercount failure), and RECON-F-003 (trust line not set — same root: object existence not verified before transacting) all link to this pattern. Frequency 3, avg usefulness 9 — escalate to candidate immediately. Draft a "XRPL Reserve — What Eats Your XRP" warning entry for Society Libraries.
CONFIDENCE:           high
LIBRARY_TARGET:       warning
LINKED_PATTERN_IDS:   P-SAFE-001
SOURCE_TYPES:         platform, internal_kb
ASSET_TYPES:          bot, workflow
```

---

## P-SAFE-001

```
PATTERN_ID:           P-SAFE-001
PATTERN_TYPE:         repeated_safety_issue
TITLE:                XRPL key and seed exposure via unsafe storage or sharing
SUMMARY:              Across the new safety collection, a consistent pattern emerges: builders and users expose XRPL seeds and private keys through unsafe practices — pasting into chat, storing in plain text, hardcoding in scripts, logging in output. The failure modes are: (1) single-key accounts used for trading bots (compromise = total loss); (2) master keys kept online instead of cold; (3) seeds shared with support or AI tools. All three result in permanent, irrecoverable loss.
KEY_INSIGHT:          The root of XRPL key safety failures is that the consequences of exposure are permanent and on-chain — no chargebacks, no recovery. Every system that signs XRPL transactions needs a documented key lifecycle: how it was generated, where it lives, who can access it, and what happens if it's compromised. Build the answer before building the bot.
CATEGORY:             safety
TAGS:                 xrpl, seed, private-key, exposure, key-management, security, cold-wallet, regular-key
LINKED_ENTRY_IDS:     RECON-S-001, RECON-S-002, RECON-S-004, RECON-S-005
FREQUENCY:            4
FIRST_SEEN:           2026-04-09
LAST_SEEN:            2026-04-09
AVERAGE_USEFULNESS:   9.25
MAX_USEFULNESS:       10
TIER_CEILING:         public
PROMOTION_STATUS:     candidate
SAFETY_STATUS:        clear
RECOMMENDED_ACTION:   create_warning
NOTES:                Four safety entries all address the same underlying failure: inadequate key lifecycle discipline. Pattern is confirmed and high-signal. Recommend drafting a "XRPL Key Safety — The Non-Negotiables" library entry covering: generation, storage, isolation via regular keys, rotation procedures, and incident response (sweep immediately). Max usefulness 10 (RECON-S-004) is the highest in the entire collection.
CONFIDENCE:           high
LIBRARY_TARGET:       warning
LINKED_PATTERN_IDS:   P-FAIL-001
SOURCE_TYPES:         internal_kb
ASSET_TYPES:          bot, workflow, project
```

---

## Pattern Register Summary

| Pattern ID | Type | Title | Frequency | Avg Usefulness | Status | Action |
|------------|------|-------|-----------|----------------|--------|--------|
| P-FRIC-001 | repeated_friction | Users underestimate agent capabilities | 4 | 7.75 | review_ready | create_guide |
| P-FRIC-002 | repeated_friction | Billing misconceptions at onboarding | 4 | 8.25 | review_ready | create_guide |
| P-FRIC-003 | repeated_friction | Agent persistence ≠ process persistence | 2 | 8.0 | watch | create_guide |
| P-FRIC-004 | repeated_friction | XRPL mainnet vs EVM — wrong environment chosen | 3 | 9.0 | candidate | create_guide |
| P-FAIL-001 | repeated_failure | XRPL reserve undercount — object count not tracked | 3 | 9.0 | candidate | create_warning |
| P-SAFE-001 | repeated_safety_issue | XRPL key/seed exposure via unsafe storage or sharing | 4 | 9.25 | candidate | create_warning |

---

---

## P-FAIL-002

```
PATTERN_ID:           P-FAIL-002
PATTERN_TYPE:         repeated_failure
TITLE:                EVM contracts without receive() causing permanent fund loss
SUMMARY:              EVM contracts participating in financial pipelines that lack receive() or fallback() functions permanently lock any ETH/XRP sent directly to them. Confirmed in Predator's legacy executor. A silent, unrecoverable failure with no on-chain error — funds simply vanish from the sender's perspective.
KEY_INSIGHT:          receive() payable is mandatory for any EVM contract that handles fund flows. Its absence is not a warning — it is a permanent loss event. Every contract audit must verify this before deployment.
CATEGORY:            failures
TAGS:                evm, solidity, receive-function, fallback, stuck-funds, executor, contract-audit
LINKED_ENTRY_IDS:    RECON-A-004, RECON-F-006
FREQUENCY:           2
FIRST_SEEN:          2026-04-09
LAST_SEEN:           2026-04-09
AVERAGE_USEFULNESS:  9.5
MAX_USEFULNESS:      10
TIER_CEILING:        public
PROMOTION_STATUS:    candidate
SAFETY_STATUS:       clear
RECOMMENDED_ACTION:  create_warning
NOTES:               Real-world confirmed. RECON-F-006 scored 10/10 — highest usefulness entry in collection. Priority warning for Society Libraries EVM section.
CONFIDENCE:          high
LIBRARY_TARGET:      warning
SOURCE_TYPES:        agent
AGENT_NAMES:         Predator
```

---

## P-FAIL-003

```
PATTERN_ID:           P-FAIL-003
PATTERN_TYPE:         repeated_failure
TITLE:                Silent exception swallowing in financial automation critical path
SUMMARY:              Financial automation bots that catch exceptions without logging them create invisible failure modes — the system appears to be running while silently dropping data, missing trades, or corrupting state. Found in Predator's build_data() function. The fix is logging with full traceback before any other error handling.
KEY_INSIGHT:          In any financial automation, a silent failure is worse than a loud crash. A crash stops the system and triggers investigation. A silent failure lets the system keep running while bleeding value with no observable signal. Every exception in the critical path must log with full traceback — non-negotiable.
CATEGORY:            failures
TAGS:                trading-bot, exception-handling, silent-failure, logging, audit, critical-path
LINKED_ENTRY_IDS:    RECON-A-003, RECON-F-005
FREQUENCY:           2
FIRST_SEEN:          2026-04-09
LAST_SEEN:           2026-04-09
AVERAGE_USEFULNESS:  9.0
MAX_USEFULNESS:      9
TIER_CEILING:        public
PROMOTION_STATUS:    candidate
SAFETY_STATUS:       clear
RECOMMENDED_ACTION:  create_guide
NOTES:               Pattern confirmed across Predator audit and general bot failure entries. Strong candidate for a "Bot audit checklist" guide in Society Libraries.
CONFIDENCE:          high
LIBRARY_TARGET:      guide
SOURCE_TYPES:        agent, platform
AGENT_NAMES:         Predator
```

---

## Next Available Pattern IDs

| Code | Next ID |
|------|---------|
| FRIC | P-FRIC-005 |
| FAIL | P-FAIL-002 |
| FIX  | P-FIX-001 |
| QUEST | P-QUEST-001 |
| RISK | P-RISK-001 |
| FLOW | P-FLOW-001 |
| TOOL | P-TOOL-001 |
| ARCH | P-ARCH-001 |
| OPT  | P-OPT-001 |
| SAFE | P-SAFE-002 |
