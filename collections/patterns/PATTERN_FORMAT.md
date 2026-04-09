# Recon Pattern Record Format — v1
> Date: 2026-04-09
> Purpose: Store recurring themes, failures, fixes, friction points, risks, and workflows detected across multiple entries.
> A pattern is confirmed when FREQUENCY ≥ 2. Single-occurrence observations stay in entries only.

---

## Pattern ID Format

```
P-[TYPE CODE]-[SEQUENCE]

Type codes:
  FRIC  = repeated_friction
  FAIL  = repeated_failure
  FIX   = repeated_fix
  QUEST = repeated_question
  RISK  = repeated_risk
  FLOW  = repeated_workflow
  TOOL  = repeated_tool_usage
  ARCH  = repeated_architecture
  OPT   = repeated_optimization
  SAFE  = repeated_safety_issue
  UNK   = unknown
```

Examples: P-FRIC-001, P-FAIL-003, P-SAFE-001

---

## Required Fields

```
PATTERN_ID:           [P-TYPE-000 format]
PATTERN_TYPE:         [repeated_failure | repeated_fix | repeated_question | repeated_friction |
                       repeated_risk | repeated_workflow | repeated_tool_usage |
                       repeated_architecture | repeated_optimization | repeated_safety_issue | unknown]
TITLE:                [short, clear, searchable]
SUMMARY:              [what the pattern is and why it matters]
KEY_INSIGHT:          [strongest single takeaway]
CATEGORY:             [onboarding | tools | workflows | strategies | failures | fixes |
                       optimizations | safety | system_design | friction | unknown]
TAGS:                 [comma-separated]
LINKED_ENTRY_IDS:     [comma-separated RECON IDs]
FREQUENCY:            [count of linked entries]
FIRST_SEEN:           [YYYY-MM-DD]
LAST_SEEN:            [YYYY-MM-DD]
AVERAGE_USEFULNESS:   [1–10, average across linked entries]
MAX_USEFULNESS:       [highest usefulness among linked entries]
TIER_CEILING:         [public | shared | restricted | secret]
PROMOTION_STATUS:     [watch | candidate | review_ready | draftable | published | blocked]
SAFETY_STATUS:        [clear | needs_anonymization | restricted_handling | blocked_from_promotion]
RECOMMENDED_ACTION:   [monitor | create_guide | create_warning | request_audit |
                       link_existing_fix | escalate_safety_review | keep_internal_only]
NOTES:                [internal context]
```

## Optional Fields

```
LINKED_PATTERN_IDS:   [related pattern IDs]
SOURCE_TYPES:         [agent | user | tool | platform | external_source]
AGENT_NAMES:          [agents commonly associated]
ASSET_TYPES:          [bot | workflow | tool | guide | project | other]
CONFIDENCE:           [low | medium | high]
LIBRARY_TARGET:       [guide | faq | warning | troubleshooting_note | architecture_note | onboarding_entry]
```

---

## Promotion Status Logic

| Status | Meaning |
|--------|---------|
| watch | Pattern emerging — FREQUENCY 2–3, monitoring |
| candidate | FREQUENCY ≥ 3 or high usefulness — worth developing |
| review_ready | Cleaned, linked, ready for human or Recon review |
| draftable | Approved for drafting into library content |
| published | Library entry exists |
| blocked | Safety or permission issue prevents promotion |

---

## Rules

1. A pattern is created when FREQUENCY reaches 2 across distinct entries
2. Every time a new entry links to an existing pattern, update FREQUENCY and LAST_SEEN
3. TIER_CEILING always reflects the most sensitive tier present in any linked entry
4. RECOMMENDED_ACTION is reassessed every time FREQUENCY increments
5. LINKED_ENTRY_IDS must stay current — no orphaned pattern records
6. Patterns are never deleted — if resolved, mark PROMOTION_STATUS: published and note resolution
