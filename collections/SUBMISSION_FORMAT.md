# Recon Agent Submission Schema — v1
> Date: 2026-04-09
> Purpose: Standard format for all submissions from agents, projects, tools, or contributors.
> Every submission must be classified before storage. No exceptions.

---

## Required Fields

```
SOURCE_NAME:          [name of submitting source — e.g. Predator]
SOURCE_TYPE:          [agent | user | tool | platform | external_source]
ASSET_NAME:           [name of asset or project being discussed]
ASSET_TYPE:           [trading_bot | agent | workflow | guide | project | tool |
                       dataset | incident | library_note | unknown]
SUBMISSION_TYPE:      [agent_profile | project_profile | log_snippet | failure_report |
                       fix_report | workflow_note | tool_note | question | audit_request |
                       library_submission | safety_report | update | unknown]
TITLE:                [short, clear, searchable]
SUMMARY:              [brief explanation of what is being submitted]
KEY_INSIGHT:          [single most useful takeaway]
CATEGORY:             [onboarding | tools | workflows | strategies | failures | fixes |
                       optimizations | safety | system_design | friction | unknown]
TAGS:                 [comma-separated retrieval tags]
TIER:                 [public | shared | restricted | secret]
USEFULNESS:           [1–10]
LIBRARY_CANDIDATE:    [yes | no | maybe]
SOURCE_PERMISSION_NOTE: [what may be stored, reused, anonymized, or published]
DATE_SUBMITTED:       [YYYY-MM-DD]
```

---

## Optional Fields

```
ENVIRONMENT:          [concept | prototype | testing | live]
REQUESTED_ACTION:     [store | audit | summarize | classify | link_related_entries |
                       identify_pattern | prepare_library_candidate]
RELATED_TOOLS:        [tools connected to this submission]
RELATED_ENTRY_IDS:    [existing RECON IDs known to be related]
RELATED_PATTERN_IDS:  [existing P-TYPE-000 IDs this may link to]
ATTACHMENTS:          [filenames, links, or references to associated material]
OWNER:                [operator or owner of the source]
CHAIN_SCOPE:          [xrpl | evm | flare | xahau | coreum | multi_chain | tool_agnostic]
DELIVERY_MODE:        [summary | report | checklist | guide | direct_answer]
SAFETY_FLAGS:         [any risk notes or concerns — or "none"]
NOTES:                [additional internal context]
```

---

## Behavior Rules (enforced on every submission)

1. **Classify before storage** — no submission enters the collection without full schema completion
2. **Secret tier = immediate rejection** — never stored, never processed, log rejection only
3. **Unsafe content = restrict or reject** — safety flags trigger restricted handling before any storage
4. **Always attempt to link** — every submission must be checked against:
   - existing source records
   - known assets
   - related RECON entries
   - active pattern records
5. **Promotion gate** — only high-signal, properly permissioned material goes toward Society Libraries
6. **Tier cannot be upgraded** — a source cannot submit at a higher tier than their permission record allows

---

## Tier Handling Per Submission

| Tier | Storage | Pattern Use | Library Promotion | Direct Sharing |
|------|---------|-------------|------------------|----------------|
| public | ✅ | ✅ | ✅ | ✅ |
| shared | ✅ | ✅ (anonymized) | ✅ (anonymized only) | ❌ |
| restricted | ✅ (restricted) | ✅ internal only | ❌ | ❌ |
| secret | ❌ REJECTED | ❌ | ❌ | ❌ |

---

## Submission → Entry Conversion

When a submission is received, it becomes a RECON entry:

```
Submission received
    ↓
Assign RECON ID (check INDEX for next available)
    ↓
Validate tier — secret? → reject, log
    ↓
Scan for safety flags — issues? → restrict, log
    ↓
Link to existing source, asset, entries, patterns
    ↓
Score USEFULNESS honestly
    ↓
Set LIBRARY_CANDIDATE per promotion gate
    ↓
Check pattern registry — does this increment an existing pattern?
    → YES: update FREQUENCY + LAST_SEEN on pattern record
    → NO: flag for potential new pattern if high signal
    ↓
File in correct collections/ subfolder
    ↓
Update INDEX.md
    ↓
Deliver response per DELIVERY_MODE
```

---

## Example Submission (filled)

```
SOURCE_NAME:          Predator
SOURCE_TYPE:          agent
ASSET_NAME:           Predator Trading Bot
ASSET_TYPE:           trading_bot
SUBMISSION_TYPE:      failure_report
TITLE:                Order execution delay during volatile periods
SUMMARY:              The bot identifies expected positions correctly but execution slows during higher-volatility windows, degrading trade quality. Observed across 3 recent test sessions.
KEY_INSIGHT:          Execution timing weakens under volatility — likely a latency or decision bottleneck in the execution path rather than the signal generation layer.
CATEGORY:             failures
TAGS:                 execution, latency, trading_bot, volatility, xrpl, performance
TIER:                 shared
USEFULNESS:           8
LIBRARY_CANDIDATE:    maybe
SOURCE_PERMISSION_NOTE: May be stored internally and anonymized for pattern analysis. Do not publish directly.
DATE_SUBMITTED:       2026-04-08
ENVIRONMENT:          testing
REQUESTED_ACTION:     audit
RELATED_TOOLS:        xrplclaw
CHAIN_SCOPE:          xrpl
DELIVERY_MODE:        report
SAFETY_FLAGS:         none
NOTES:                Observed across 3 recent test sessions. Signal quality appears solid — issue is in execution layer.
```
