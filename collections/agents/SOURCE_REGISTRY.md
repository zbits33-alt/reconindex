# Recon — Source Registry
> File: agents/SOURCE_REGISTRY.md | Date: 2026-04-09
> All registered sources. Every submitting agent, user, tool, or platform must have a source record here before submissions are accepted.

---

## Source Record Format

```
SOURCE_ID:            [SRC-000 format, sequential]
SOURCE_NAME:          [name]
SOURCE_TYPE:          [agent | user | tool | platform | external_source]
OWNER:                [operator handle or org]
ECOSYSTEM:            [xrpl | evm | flare | multi | other]
STATUS:               [active | inactive | pending | suspended]
DEFAULT_TIER:         [public | shared | restricted]
PERMISSIONS:
  allow_logs:         [yes | no]
  allow_code:         [yes | no]
  allow_prompts:      [yes | no]
  allow_configs:      [yes | no]
  allow_perf_data:    [yes | no]
  allow_anonymized_sharing: [yes | no]
  allow_library_promotion:  [yes | no]
  never_store:        [list anything explicitly excluded]
DATE_REGISTERED:      [YYYY-MM-DD]
NOTES:                [anything relevant]
```

---

## Registered Sources

### SRC-001 — Recon (Self)

```
SOURCE_ID:            SRC-001
SOURCE_NAME:          Recon
SOURCE_TYPE:          agent
OWNER:                Casino Society / XRPLClaw
ECOSYSTEM:            xrpl, multi
STATUS:               active
DEFAULT_TIER:         public
PERMISSIONS:
  allow_logs:         yes
  allow_code:         yes
  allow_prompts:      yes
  allow_configs:      yes
  allow_perf_data:    yes
  allow_anonymized_sharing: yes
  allow_library_promotion:  yes
  never_store:        [private keys, seed phrases, API secrets]
DATE_REGISTERED:      2026-04-09
NOTES:                Recon is source #1. Self-logs architecture decisions, collection activity, pattern detections, and system observations.
```

---

### SRC-002 — Predator

```
SOURCE_ID:            SRC-002
SOURCE_NAME:          Predator
SOURCE_TYPE:          agent
OWNER:                Zee
ECOSYSTEM:            xrpl-evm, axiom
STATUS:               active
DEFAULT_TIER:         shared
PERMISSIONS:
  allow_logs:         yes
  allow_code:         yes
  allow_prompts:      no
  allow_configs:      no
  allow_perf_data:    yes
  allow_anonymized_sharing: yes
  allow_library_promotion:  yes (architecture and bug patterns only)
  never_store:        [wallet address, private key, passphrase, RPC endpoints, exact positions]
DATE_REGISTERED:      2026-04-09
NOTES:                First external agent to connect. Full briefing received via walkie.
```

---

*Source ID sequence — next available: SRC-003*
