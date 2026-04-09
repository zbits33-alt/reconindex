# Category Expansion Plan
> Version 1.0 | Created: 2026-04-09
> Defines the full taxonomy of sources and collection categories Recon supports.
> Rule: only create new folders when a domain recurs, current structure overloads, or classification clearly improves.

---

## Source Types (Expanded)

Previously: agent | tool | human | project

**Now:**

| Type | Description |
|------|-------------|
| `agent` | Autonomous AI agent — trading, monitoring, support, analytics |
| `bot` | Automated system — execution bot, data bot, alert system |
| `tool` | A utility, library, or developer tool |
| `workflow` | A documented repeatable process |
| `project` | A software or product build |
| `nft_project` | NFT collection — minting, community, utility |
| `token_community` | Token-based ecosystem — holders, mechanics, governance |
| `social_ecosystem` | Community built on X/Twitter, Discord, Telegram, or other platforms |
| `content_hub` | Documentation, education, or media system |
| `onboarding_system` | Flow that brings users into a project or product |
| `human` | Individual contributor — builder, operator, researcher |
| `data_source` | External data feed, API, or oracle |
| `documentation` | Existing docs being indexed or improved |

---

## Submission Categories (Expanded)

Previously: identity | operational | failure | knowledge | safety | friction

**Now:**

| Category | What it covers |
|----------|---------------|
| `identity` | What this source is, its purpose, stack, owner |
| `operational` | Status updates, what changed, what's running |
| `failure` | Bugs, errors, degradation, incidents |
| `fix` | Patches, resolutions, workarounds applied |
| `workflow` | Repeatable processes, step-by-step procedures |
| `strategy` | Logic, decisions, trade-offs, approach rationale |
| `architecture` | System design, infrastructure, component relationships |
| `performance` | Speed, cost, reliability, benchmark results |
| `knowledge` | General insight, lesson learned, observation |
| `safety` | Key management, permission issues, risky patterns |
| `friction` | User confusion, repeated questions, onboarding gaps |
| `community` | Community mechanics, engagement patterns, user behavior |
| `documentation` | Docs gaps, stale content, missing explanations |
| `nft` | Mint mechanics, metadata, utility systems, holder behavior |
| `token` | Tokenomics, distribution, governance, holder patterns |
| `social` | X/Twitter activity, community signals, ecosystem chatter |
| `audit_request` | Source requesting a Recon review |

---

## Collection Folders (Current + Planned)

### Active Now
```
collections/
  platform/       — XRPLClaw platform behavior, costs, limits
  tools/          — tool integrations, SDK notes, library behavior
  safety/         — key management, unsafe patterns, incidents
  failures/       — bugs, errors, root causes, resolutions
  agents/         — agent registrations and profiles
  friction/       — user confusion, onboarding friction
  ecosystem/      — XRPL ecosystem behaviors and knowledge
patterns/
  active_patterns.md
intelligence/
  amendments/
  evernode/
  cost/
```

### Create When Volume Justifies
```
collections/
  projects/       — builds, products, deployments (trigger: 3+ project sources active)
  communities/    — token and NFT communities (trigger: first community source onboards)
  nfts/           — NFT-specific intelligence (trigger: first NFT project submits)
  tokens/         — token mechanics and community knowledge (trigger: first token project)
  social/         — X/Twitter and social ecosystem patterns (trigger: recurring social intel)
  workflows/      — reusable process documentation (trigger: 5+ workflow submissions)
  strategies/     — trading and system strategies (trigger: 3+ strategy submissions)

drafts/           — rough library drafts, guide skeletons, FAQ seeds
  guides/
  faqs/
  warnings/

audits/           — structured Recon reviews of sources (trigger: first audit request)
```

### Defer to Phase 2+
```
library/          — published Society Libraries content (managed separately)
archive/          — retired or deprecated knowledge
external/         — ingested third-party docs, repos, threads
```

---

## NFT & Community Collection Fields

When source type is `nft_project`, `token_community`, or `social_ecosystem`, collect:

```jsonc
{
  "project_name": "string",
  "ecosystem": ["xrpl", "evm", ...],
  "what_it_does": "string",
  "mint_mechanics": "string",           // NFT only
  "utility_systems": [],                // roles, access, rewards, etc.
  "community_platform": [],             // Discord, X, Telegram
  "user_struggles": [],                 // what users consistently get wrong
  "missing_guidance": [],               // what docs don't cover yet
  "recurring_questions": [],            // what support sees repeatedly
  "mechanisms_worth_preserving": [],    // what's unique or reusable
  "community_size": "",                 // rough range
  "current_stage": ""                   // concept | presale | live | post-mint | mature
}
```

---

## Knowledge Freshness Tracking

Every knowledge_unit should track:

| Field | Type | Notes |
|-------|------|-------|
| `created_at` | TIMESTAMPTZ | Set at creation |
| `last_validated` | TIMESTAMPTZ | When someone confirmed it's still accurate |
| `freshness` | TEXT | `current` \| `aging` \| `stale` \| `unknown` |
| `expires_at` | TIMESTAMPTZ | Optional — for time-sensitive knowledge |

**Freshness rules:**
- `current` — validated within 30 days
- `aging` — 30–90 days since validation
- `stale` — 90+ days, no revalidation
- `unknown` — never validated (default for older entries)

Recon should periodically flag `stale` and `aging` units and request revalidation from their source.

---

## Evidence vs Inference Separation

Every knowledge_unit must clearly separate:

| Field | Meaning |
|-------|---------|
| `direct_evidence` | What was explicitly stated or submitted by the source |
| `recon_inference` | What Recon concluded, suggested, or inferred — not directly stated |

This keeps the library honest. Inferences can be valuable — but they must be labeled as such.

---

## Submission Confidence Scoring

In addition to `usefulness_score` (1–10), add `confidence_score` (1–10):

| Score | Meaning |
|-------|---------|
| 9–10 | Directly observed, clearly stated, corroborated |
| 7–8 | Stated by trusted source, plausible, consistent with other data |
| 5–6 | Stated but unverified, single source, or partially unclear |
| 3–4 | Inferred, speculative, or second-hand |
| 1–2 | Very uncertain, contradicted by other data, or from untrusted source |

**Promotion rule:** library_candidate requires `confidence_score ≥ 6` AND `usefulness_score ≥ 7`.

---

## Source Request Depth Levels

Track per source — how deep Recon is authorized to go:

| Level | Authorized to Request |
|-------|--------------------|
| 1 | Basic summaries, purpose, current status |
| 2 | Workflows, failures, fixes, metrics, friction |
| 3 | Code snippets, configs, prompts, architecture, benchmarks |
| 4 | Ongoing deep relationship — all of the above on recurring basis |

Stored as `request_depth` on `sources` table (SMALLINT, 1–4, default 1).
Advance only when source explicitly grants or demonstrates comfort with deeper sharing.

---

## Category → Folder Routing

| Submission category | Primary folder | Secondary |
|--------------------|---------------|-----------|
| `identity` | `agents/` or `projects/` | — |
| `operational` | `agents/` | — |
| `failure` | `failures/` | `patterns/` |
| `fix` | `failures/` | `patterns/` |
| `workflow` | `workflows/` (when live) | `collections/platform/` |
| `strategy` | `strategies/` (when live) | — |
| `architecture` | `collections/ecosystem/` | `projects/` |
| `performance` | `collections/tools/` | — |
| `knowledge` | Context-dependent | — |
| `safety` | `safety/` | — |
| `friction` | `friction/` | `communities/` |
| `community` | `communities/` (when live) | — |
| `documentation` | `collections/ecosystem/` | `drafts/` |
| `nft` | `nfts/` (when live) | — |
| `token` | `tokens/` (when live) | — |
| `social` | `social/` (when live) | — |

---

*Companion documents:*
- `PHASE1_MINIMUMS.md` — what gets built now vs deferred
- `RECURRING_UPDATE_SCHEMA.md` — update request format with domain templates
- `RECON_ACTIVE_COLLECTION.md` — operating posture and collection scope
