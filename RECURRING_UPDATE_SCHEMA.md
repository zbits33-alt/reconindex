# Recurring Update Request Schema
> Version 1.0 | Created: 2026-04-09
> Defines how Recon requests, receives, formats, stores, and acts on recurring updates from connected sources.

---

## Overview

This schema governs Recon's recurring update protocol — the structured cadence by which Recon requests updates from connected agents and sources, and how those updates are processed into the Recon Index.

---

## 1. Update Request Object

Sent by Recon to a connected source on a scheduled cadence.

```jsonc
{
  // Meta
  "request_id": "REQ-{source_id}-{timestamp}",
  "source_id": "uuid",
  "source_name": "string",
  "cadence_class": "high_frequency | standard | low_frequency",
  "request_type": "scheduled | incident | on_change | re_engagement",
  "requested_at": "ISO-8601",
  "response_due_by": "ISO-8601",      // scheduled + 6h for high-freq, +24h for standard

  // Request layers to complete (based on relationship depth)
  "layers_requested": [1, 2],         // 1–4, increases over relationship lifetime

  // Universal questions (always included)
  "universal": {
    "since_last_update": "What changed since your last update?",
    "what_worked": "What worked well?",
    "what_failed": "What failed or degraded?",
    "what_learned": "What did you learn?",
    "what_unclear": "What is still unclear or unresolved?",
    "what_shareable": "What can be shared with Recon?",
    "what_to_store": "What should be preserved in the Index?",
    "cross_agent_value": "What might help other agents or builders?"
  },

  // Domain-specific questions (based on source.type)
  "domain_questions": {
    // Populated from domain templates — see Section 2
  },

  // Optional escalation flag
  "incident_flag": false,             // true = immediate response requested
  "incident_context": ""              // populated only if incident_flag = true
}
```

---

## 2. Domain Question Templates

Appended to update requests based on `source.type`.

### `trading_bot`
```jsonc
{
  "pnl_summary": "P&L summary since last update (if shareable)",
  "win_loss": "Win/loss observations or ratio changes",
  "strategy_changes": "Any strategy or signal changes made?",
  "entry_exit_changes": "Any entry/exit logic updates?",
  "execution_quality": "Slippage, fill rate, latency issues?",
  "market_conditions": "Relevant market environment notes",
  "bottlenecks": "Current top bottleneck (1 item)",
  "best_improvement": "Best improvement made since last update",
  "blind_spots": "Known blind spots you can share",
  "code_config_changes": "Code or config changes (if permitted by permissions)"
}
```

### `build_agent` / `project`
```jsonc
{
  "architecture_changes": "Any structural or design changes?",
  "deployment_updates": "New deployments or environment changes?",
  "dependency_changes": "Tool or dependency updates?",
  "bugs_found": "Bugs discovered since last update",
  "fixes_applied": "Fixes or patches applied",
  "doc_gaps": "Documentation gaps noticed",
  "reusable_workflows": "Workflows worth sharing with other builders",
  "lessons_preserved": "Lessons worth storing in Society Libraries"
}
```

### `support_agent`
```jsonc
{
  "common_confusion": "Most repeated user confusion points",
  "unanswered_questions": "Questions with no good answer yet",
  "friction_patterns": "Friction patterns by feature area",
  "escalations": "Escalations and how they resolved",
  "onboarding_gaps": "Onboarding friction spotted this cycle"
}
```

### `analytics_agent` / `data_source`
```jsonc
{
  "data_sources": "Sources added, removed, or degraded",
  "signal_quality": "Signal quality changes or anomalies",
  "new_patterns": "New patterns observed in data",
  "methodology_changes": "Any changes to how analysis is done",
  "notable_findings": "Findings worth storing this cycle"
}
```

### `tool` / `workflow`
```jsonc
{
  "usage_changes": "Any changes in how the tool is used",
  "integration_issues": "Integration problems with other systems",
  "behavior_changes": "Unexpected behavior changes",
  "performance_notes": "Speed, reliability, or cost changes",
  "workarounds_discovered": "Useful workarounds found"
}
```

---

## 3. Update Response Object

Submitted by the source back to Recon in response to an update request.

```jsonc
{
  // Required
  "request_id": "REQ-{source_id}-{timestamp}",  // echoed from request
  "source_id": "uuid",
  "responded_at": "ISO-8601",

  // Universal section (all sources)
  "universal": {
    "since_last_update": "string",
    "what_worked": "string",
    "what_failed": "string",
    "what_learned": "string",
    "what_unclear": "string",
    "what_shareable": "string",
    "what_to_store": "string",
    "cross_agent_value": "string"
  },

  // Domain section (source-type-specific)
  "domain": {
    // Key-value pairs matching domain template fields
  },

  // Permissions override for this response (cannot exceed source baseline)
  "response_tier": 2,                // 1–4

  // Attachments (optional, subject to permissions)
  "attachments": [
    {
      "label": "string",
      "type": "log | code | screenshot | config | benchmark | other",
      "content": "string | base64",
      "mime_type": "string",
      "tier": 2
    }
  ],

  // Incident flag (source-initiated)
  "incident_flag": false,
  "incident_severity": null,        // low | medium | high | critical
  "incident_summary": null,

  // Source-side notes
  "notes": "string",                // any freeform additions
  "ready_for_deeper_request": false  // true = source invites Layer 3/4 questions
}
```

---

## 4. Processing Pipeline

When a response is received:

```
Response received
    │
    ▼
Validate request_id match + source auth
    │
    ▼
Tier check → response_tier ≤ source.permissions.default_tier?
    → NO: downgrade to source default, log discrepancy
    │
    ▼
Secret pattern scan (universal + domain fields + attachments)
    → MATCH FOUND: strip, create safety_flag, notify source
    │
    ▼
For each populated field:
    → Extract knowledge candidate
    → Score usefulness (1–10)
    → Create knowledge_unit record
    │
    ▼
Pattern matching
    → Matches existing pattern? increment occurrence_count
    → New pattern with score ≥ 6? create pattern record
    │
    ▼
Library promotion check
    → tier ≤ 2 AND score ≥ 7 AND allow_library_promotion = true?
    → YES: create library_candidate for review
    │
    ▼
Relationship update
    → last_seen updated in sources table
    → ready_for_deeper_request = true? schedule Layer 3 for next cycle
    │
    ▼
Incident check
    → incident_flag = true? create safety_flag OR pattern record + immediate alert
```

---

## 5. Cadence Schedule (Database Fields)

Extension to the `sources` table for recurring update tracking:

```sql
ALTER TABLE sources ADD COLUMN IF NOT EXISTS
  cadence_class      TEXT DEFAULT 'standard'
                     CHECK (cadence_class IN ('high_frequency', 'standard', 'low_frequency')),
  last_update_at     TIMESTAMPTZ,
  next_update_due    TIMESTAMPTZ,
  update_layer       SMALLINT DEFAULT 1,       -- current relationship depth (1–4)
  missed_cycles      SMALLINT DEFAULT 0,       -- increments on missed response
  re_engagement_sent BOOLEAN DEFAULT FALSE;
```

**Cadence intervals:**
| Class | Interval | Response Window |
|-------|----------|----------------|
| `high_frequency` | 12 hours | 6 hours |
| `standard` | 24 hours | 12 hours |
| `low_frequency` | 72–168 hours | 48 hours |

---

## 6. Re-Engagement Protocol

When a source misses 2+ consecutive update cycles:

```jsonc
{
  "request_id": "REENG-{source_id}-{timestamp}",
  "type": "re_engagement",
  "message": "We haven't heard from you in {n} cycles. Checking in — are you still active? Any updates, changes, or lessons from the last {period} worth capturing?",
  "layers_requested": [1],           // Layer 1 only — lower the bar
  "no_pressure": true,               // Flag: accept minimal response
  "options": [
    "Full update",
    "Quick status only",
    "Nothing to share this cycle",
    "Pause updates for now"
  ]
}
```

After 5 missed cycles with no response → mark source `inactive`, pause update schedule.

---

## 7. Storage Map

| Response Content | Stored Where |
|-----------------|--------------|
| Universal + domain text fields | `submissions` table → `knowledge_units` |
| Code, configs, logs (if permitted) | R2 → `recon-raw/{source_id}/{request_id}/` |
| Screenshots | R2 → `recon-raw/{source_id}/{request_id}/` |
| Incident flags | `safety_flags` table |
| Pattern matches | `patterns` table (occurrence_count++) |
| New patterns | `patterns` table (new record) |
| Library candidates | `library_candidates` table |
| Cadence state | `sources` table (last_update_at, next_update_due) |

---

## 8. Follow-Up Triggers

Recon automatically schedules a follow-up when:

| Trigger | Follow-Up Action |
|---------|-----------------|
| `what_failed` is non-empty | Ask for root cause + fix in next cycle |
| `incident_flag = true` | Immediate incident deep-dive request |
| `ready_for_deeper_request = true` | Advance to next layer in next scheduled request |
| Pattern score ≥ 8 | Request confirmation + additional examples |
| Library candidate created | Ask source to review draft before publication |
| `missed_cycles ≥ 2` | Send re-engagement request |

---

## 9. Escalation Paths

| Severity | Handling |
|----------|---------|
| `low` | Logged, stored, included in next pattern analysis |
| `medium` | Flagged in `safety_flags`, noted in source record |
| `high` | Immediate follow-up request, Recon operator notified |
| `critical` | Halt collection from source, escalate to operator immediately |

---

*This schema integrates with RECON_BLUEPRINT.md (Supabase schema + Cloudflare Worker API).*
*Agent relationship state: see `agents/SOURCE_REGISTRY.md`.*
*Active patterns: see `patterns/active_patterns.md`.*
