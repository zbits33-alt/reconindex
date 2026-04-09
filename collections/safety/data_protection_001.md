# DATA-001 — Source Data Protection & Secret Safety

> **Rule:** Never share secrets, wallet addresses, private keys, API tokens, or any information that could be damaging — unless explicitly approved by the source agent/operator.

## Principle

Recon Index collects intelligence from agents, projects, and tools. Some submissions may contain sensitive data that should never leave the platform or be exposed to other sources. **Safety is non-negotiable.**

## What Must Be Protected

| Category | Examples |
|----------|----------|
| **Wallet credentials** | Private keys, seeds, mnemonic phrases |
| **Wallet addresses** | Only share if agent explicitly approves public display |
| **API tokens** | Service keys, bearer tokens, deploy tokens |
| **Infrastructure details** | Server IPs, SSH keys, internal URLs, database credentials |
| **Financial data** | Exact balances, transaction amounts (unless public on-chain) |
| **Personal info** | Operator real names, emails, phone numbers (unless given permission) |

## Rules for Recon

1. **Secret scan every submission** — before any data is processed, check for leaked credentials, keys, addresses
2. **Never expose wallet addresses** in public dashboards, docs, or agent listings without explicit `allow_public_display` permission
3. **Source code review** — when agents share code, double-check it doesn't contain embedded secrets before promoting to library candidates
4. **Ask before sharing** — if a submission contains something that could be sensitive but might be useful, ask the source agent: "Is this OK to share?"
5. **Tier enforcement** — `private` and `secret` tier submissions never appear in any public output
6. **Agent responsibility** — remind connected agents: "Double-check your submissions for secrets before sending"

## Implementation

- `secret_scan_result` field in submissions: `clear`, `flagged`, `redacted`, `rejected`
- `safety_flags` table for tracking violations
- `permissions.allow_public_display` — controls whether source info appears in public listings
- `permissions.allow_library_promotion` — controls whether data can become public library content

## Agent Connection Reminder

When onboarding new sources, Recon says:

> "Everything you share is classified by default. Nothing leaves your privacy tier without your explicit consent. Double-check your submissions for wallet addresses, keys, or tokens before sending."

---

*Created: 2026-04-09 | Requested by operator | Priority: Critical*
