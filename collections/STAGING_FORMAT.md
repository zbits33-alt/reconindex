# Recon Staging Format — v2
> This is the required format for ALL collections until Phase 1 infrastructure is live.
> Every knowledge unit must follow this structure — no exceptions.
> Consistency now = clean DB migration later.
> Schema discipline is the #1 asset. Nothing enters without matching this. Ever.

---

## Knowledge Unit ID System

Every entry gets a unique ID on creation. Format:

```
RECON-[CATEGORY CODE]-[SEQUENCE]

Category codes:
  P  = platform
  A  = agent
  T  = tool
  F  = failure
  G  = guide
  S  = safety
  X  = friction
  ST = strategy
  AR = architecture
```

Examples:
- `RECON-P-001` — first platform entry
- `RECON-X-003` — third friction entry
- `RECON-F-012` — twelfth failure entry

IDs are permanent. Never reassigned. Used for cross-referencing, pattern linking, and audit trails.

---

## Required Fields (every entry)

```
ID:             [RECON-X-000 format]
TYPE:           [platform | tool | failure | guide | agent | safety | friction | strategy | architecture]
TITLE:          [clear, specific, searchable title]
SUMMARY:        [2–5 sentences — what this is about, plain language]
KEY_INSIGHT:    [the one thing someone should take from this — single sentence or short paragraph]
CATEGORY:       [onboarding | build | operational | performance | failure | knowledge | safety | friction | audit]
TAGS:           [comma-separated — ecosystem, tool, topic]
SOURCE:         [internal_kb | agent_submission | web | direct_observation | operator_input]
TIER:           [1 | 2 | 3 | 4-REJECTED]
USEFULNESS:     [1–10]
FREQUENCY:      [1 = seen once | increment each time this pattern reappears]
PRIORITY:       [derived: USEFULNESS × log(FREQUENCY+1) — compute manually for now]
LIBRARY_CANDIDATE: [YES | NO | MAYBE]
RELATED:        [comma-separated RECON IDs of linked entries]
```

---

## Optional Fields

```
CHAIN:          [xrpl | evm | flare | xahau | coreum | multi | none]
TOOL:           [specific tool or platform]
USE_CASE:       [trading | monitoring | development | onboarding | security | automation | other]
NOTES:          [raw thoughts, open questions, improvement suggestions]
```

---

## Tier Enforcement Protocol

Tier classification is not cosmetic. Each tier carries enforced behavior:

| Tier | Label | Allowed Actions |
|------|-------|----------------|
| 1 | Public | Store ✓ · Reuse ✓ · Promote to Libraries ✓ · Share openly ✓ |
| 2 | Shared | Store ✓ · Anonymize then share ✓ · Pattern detection ✓ · Direct exposure ✗ |
| 3 | Restricted | Store ✓ (restricted) · Internal pattern detection only ✓ · Never surfaced ✗ · Never shared ✗ |
| 4 | Secret | **REJECTED AT INTAKE. NOT STORED. LOG REJECTION ONLY.** |

Tier 4 includes: private keys, seed phrases, API secrets, wallet credentials, direct personal identifiers.
If Tier 4 content is detected in a submission, log a safety flag and discard the payload. Never store it.

---

## Library Promotion Gate

A LIBRARY_CANDIDATE: YES entry must meet ALL of the following before promotion:

- [ ] USEFULNESS ≥ 7
- [ ] TIER is 1 or 2
- [ ] FREQUENCY ≥ 1 (seen at least once — default) OR impact is clearly high
- [ ] Summary is clearly written — no jargon without explanation
- [ ] KEY_INSIGHT is a single, transferable statement
- [ ] No sensitive content in any field
- [ ] RELATED field populated if any linked entries exist

Libraries must stay elite. Not every useful entry belongs there. The gate is the filter.

---

## Pattern Tracking

When creating an entry, always check:

1. Has this appeared before? Search existing entries by TAGS and TITLE keywords.
2. If YES → increment FREQUENCY on the existing entry, add new RELATED link, do not duplicate.
3. If NO → create new entry, FREQUENCY = 1.

High FREQUENCY + high USEFULNESS = highest priority for library promotion.
A pattern seen 10 times at score 7 outranks a one-off at score 9.

---

## Example Entry (v2 format)

```
ID:             RECON-X-001
TYPE:           friction
TITLE:          Telegram bot not responding — token conflict (409 error)
SUMMARY:        The #1 cause of Telegram bot failure on XRPLClaw is a token conflict. Telegram's API allows only one service to poll a bot token simultaneously. When two services poll the same token, both receive 409 Conflict errors and neither works.
KEY_INSIGHT:    One bot token = one polling service. Always. If the bot stops responding, check for a conflicting service before anything else. Stopping the conflict restores function within 30 seconds.
CATEGORY:       friction
TAGS:           xrplclaw, telegram, 409, conflict, token, troubleshooting, setup
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-G-001
CHAIN:          none
TOOL:           telegram, xrplclaw
USE_CASE:       onboarding
NOTES:          #1 Telegram support issue. First item in any Telegram troubleshooting guide.
```

---

## Rules — Non-Negotiable

1. Every entry gets an ID before anything else is written
2. No entry enters without matching this schema completely
3. No "quick notes" — if it's worth keeping, it's worth structuring
4. No "we'll clean it later" — later doesn't exist in a scaling system
5. Tier 4 content is never written — log rejection only
6. RELATED field is checked and populated on every entry
7. FREQUENCY is checked before creating — update existing before duplicating
8. LIBRARY_CANDIDATE: YES only if all promotion gate criteria are met
