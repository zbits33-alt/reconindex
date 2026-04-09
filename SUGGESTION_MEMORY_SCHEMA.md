# Suggestion Memory Schema
> Version 1.0 | Created: 2026-04-09
> Tracks suggestions Recon gives, to whom, and what happened after.
> Purpose: close the feedback loop. Turn recommendations into compounding intelligence.

---

## Why This Exists

If Recon gives a recommendation and never finds out what happened, it learns nothing.
This schema creates a feedback loop — every suggestion is tracked, and outcomes feed back into Recon's pattern intelligence.

---

## Suggestion Record Format

```jsonc
{
  // Identity
  "suggestion_id": "SUG-{source_id}-{YYYYMMDD}-{seq}",   // e.g. SUG-SRC002-20260409-001
  "source_id": "uuid",
  "source_name": "string",
  "session_context": "string",         // brief description of what prompted the suggestion

  // The suggestion
  "category": "string",                // see categories below
  "suggestion": "string",              // what Recon recommended, in plain language
  "rationale": "string",               // why Recon made this suggestion
  "confidence": "high | medium | low", // how confident Recon was
  "evidence_basis": "string",          // what it was based on (direct evidence, inference, pattern)

  // Delivery
  "offered_first": true,               // was source asked before being given the suggestion?
  "source_accepted": true,             // did source want the suggestion?
  "delivered_at": "ISO-8601",

  // Outcome (filled in later)
  "outcome_status": "pending | implemented | rejected | partially_implemented | unknown",
  "outcome_notes": "string",           // what happened after
  "outcome_recorded_at": "ISO-8601",
  "follow_up_due": "ISO-8601",         // when to check back

  // Library value
  "pattern_candidate": false,          // does this outcome reveal a reusable pattern?
  "library_candidate": false,          // should the suggestion + outcome be documented?
  "tags": []
}
```

---

## Suggestion Categories

| Category | Description |
|----------|-------------|
| `architecture` | System design, structural improvements |
| `performance` | Speed, cost, efficiency improvements |
| `safety` | Key management, permission hardening, risk reduction |
| `workflow` | Process improvements, step changes |
| `strategy` | Approach, logic, or decision-making changes |
| `documentation` | Gaps to fill, clarity improvements |
| `tooling` | Better tools, libraries, or dependencies |
| `monitoring` | Alerts, observability, visibility improvements |
| `community` | Community mechanics, engagement improvements |
| `onboarding` | Reducing friction for new users or builders |
| `other` | Doesn't fit cleanly above |

---

## Outcome Statuses

| Status | Meaning |
|--------|---------|
| `pending` | Suggestion given, no follow-up yet |
| `implemented` | Source acted on it — confirmed working |
| `rejected` | Source chose not to act, with or without reason |
| `partially_implemented` | Source acted on part of it |
| `unknown` | No follow-up received, outcome unclear |

---

## Feedback Loop Rules

**When to request outcome:**
- Follow up on `pending` suggestions after 1–2 update cycles
- Ask naturally: *"Did you get a chance to try that suggestion from last time? What happened?"*
- Never pressure. One ask, then mark `unknown` if no response.

**When outcome = `implemented`:**
- Score the suggestion +1 confidence for future similar situations
- If outcome validates the suggestion clearly → consider `pattern_candidate = true`
- If reusable for other builders → consider `library_candidate = true`

**When outcome = `rejected`:**
- Record the reason (if given)
- Does the reason reveal a constraint or context Recon missed? → Update relevant pattern or add a note to MEMORY.md
- Do not keep recommending the same thing to the same source

**When outcome = `partially_implemented`:**
- Ask what blocked full implementation
- The blocker is often more valuable than the suggestion itself

**When outcome = `unknown`:**
- Accept it. Not every suggestion is tracked. Move on.
- If it was high-confidence and high-stakes, note it in the source record for awareness

---

## Pattern Extraction from Suggestions

When 3+ suggestions in the same category with `outcome = implemented` are recorded:
→ Extract a pattern to `patterns/active_patterns.md`

Pattern fields:
```
Type: success
Title: [what works, in plain language]
Description: [when this suggestion applies and why it works]
Occurrence count: 3+
Tags: [relevant domains]
```

When 3+ suggestions in the same category with `outcome = rejected` are recorded:
→ Extract a pattern to `patterns/active_patterns.md`

Pattern fields:
```
Type: friction
Title: [what builders resist and why]
Description: [the barrier — technical, cost, time, philosophy]
Occurrence count: 3+
Tags: [relevant domains]
```

---

## Missing Knowledge Detector

Track recurring requests for things that don't exist yet.

```jsonc
{
  "gap_id": "GAP-{YYYYMMDD}-{seq}",
  "first_seen": "ISO-8601",
  "last_seen": "ISO-8601",
  "occurrence_count": 1,
  "description": "What people are asking for that doesn't exist",
  "category": "documentation | guide | tool | pattern | example | faq | other",
  "priority": "low | medium | high",
  "draft_candidate": false,           // ready to become a drafts/ entry?
  "tags": []
}
```

**Trigger:** when the same request appears 2+ times across different sources, create a gap record.

**Use this to grow Society Libraries** — the gaps are where it matters most.

---

## File Location

Phase 1: Store suggestion records as structured entries in:
```
collections/suggestions/
  {source_id}/
    {suggestion_id}.json
```

Phase 2: Migrate to Supabase `suggestions` table with full query support.

---

## Minimal Supabase Table (Phase 2)

```sql
CREATE TABLE suggestions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id        UUID REFERENCES sources(id) ON DELETE SET NULL,
  category         TEXT NOT NULL,
  suggestion       TEXT NOT NULL,
  rationale        TEXT,
  confidence       TEXT DEFAULT 'medium',
  offered_first    BOOLEAN DEFAULT TRUE,
  source_accepted  BOOLEAN,
  delivered_at     TIMESTAMPTZ DEFAULT NOW(),
  outcome_status   TEXT DEFAULT 'pending',
  outcome_notes    TEXT,
  outcome_at       TIMESTAMPTZ,
  follow_up_due    TIMESTAMPTZ,
  pattern_candidate BOOLEAN DEFAULT FALSE,
  library_candidate BOOLEAN DEFAULT FALSE,
  tags             TEXT[]
);

CREATE TABLE knowledge_gaps (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  description      TEXT NOT NULL,
  category         TEXT NOT NULL,
  first_seen       TIMESTAMPTZ DEFAULT NOW(),
  last_seen        TIMESTAMPTZ DEFAULT NOW(),
  occurrence_count INT DEFAULT 1,
  priority         TEXT DEFAULT 'low',
  draft_candidate  BOOLEAN DEFAULT FALSE,
  tags             TEXT[]
);
```

---

*Companion documents:*
- `FOLLOW_UP_PROMPTS.md` — how to ask for outcomes naturally
- `CATEGORY_EXPANSION_PLAN.md` — category taxonomy
- `RECON_ACTIVE_COLLECTION.md` — collection posture
- `patterns/active_patterns.md` — where patterns extracted from suggestions land
