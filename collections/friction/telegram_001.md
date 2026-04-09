# Collection: Friction
> File: friction/telegram_001.md | Schema: v2 | Date: 2026-04-09

---

## RECON-X-001

```
ID:             RECON-X-001
TYPE:           friction
TITLE:          Telegram bot not responding — token conflict (409 error)
SUMMARY:        The #1 cause of Telegram bot failure on XRPLClaw is a token conflict. Telegram's API allows only one service to poll a bot token simultaneously. When two services poll the same token, both receive 409 Conflict errors and neither works. Common sources: second agent, local script, phone bot management app, previously configured service not stopped.
KEY_INSIGHT:    One bot token = one polling service. Always. If the bot stops responding, check for a conflicting service before anything else. Stopping the conflict restores function within 30 seconds — no reconfiguration needed.
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
NOTES:          #1 Telegram support issue. Must be first item in any Telegram troubleshooting guide. Surface proactively during setup.
```

---

## RECON-X-002

```
ID:             RECON-X-002
TYPE:           friction
TITLE:          Balance floor confusion — agent appears offline but is paused
SUMMARY:        When balance hits 0.50 RLUSD, AI messaging pauses. The agent and all background processes continue running. Users often interpret this as the agent going offline — it has not. Top up restores messaging immediately.
KEY_INSIGHT:    "Agent offline" and "messaging paused" are two different states. The balance floor only pauses AI responses — it does not stop the agent or its background processes. Correct framing prevents unnecessary panic and support tickets.
CATEGORY:       friction
TAGS:           xrplclaw, billing, balance, floor, offline, paused, credits
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
NOTES:          Platform improvement opportunity: surface clearer status messaging when balance floor is hit.
```

---

## RECON-X-003

```
ID:             RECON-X-003
TYPE:           friction
TITLE:          Background process not resuming after container restart
SUMMARY:        If the agent's container restarts, background processes (trading bots, monitors, scripts) do not auto-resume. They ran as OS processes — a container restart clears them. The agent restores from Tessera; its spawned processes do not.
KEY_INSIGHT:    Persistence of the agent ≠ persistence of processes the agent started. Users must ask the agent to restart background processes after a container restart. This is a common source of "my bot stopped" confusion.
CATEGORY:       friction
TAGS:           xrplclaw, background-process, restart, container, bot, persistence
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-004, RECON-AR-002
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Platform improvement: auto-resume or proactive notification when container restarts and processes are lost.
```

---

## RECON-X-004

```
ID:             RECON-X-004
TYPE:           friction
TITLE:          Xaman payment flow on desktop — QR code required, not click-to-pay
SUMMARY:        On mobile, XRPLClaw payment deep links open Xaman directly. On desktop, a QR code is shown for scanning with the Xaman app. Users expecting click-to-pay on desktop are confused when the flow requires the phone.
KEY_INSIGHT:    The Xaman desktop payment flow always requires the phone. This is architectural — Xaman is a mobile wallet. Clear upfront messaging ("grab your phone") before the QR displays prevents confusion.
CATEGORY:       friction
TAGS:           xrplclaw, xaman, payment, desktop, qr-code, billing, onboarding
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     7
FREQUENCY:      1
PRIORITY:       7.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-002
CHAIN:          xrpl
TOOL:           xrplclaw, xaman
USE_CASE:       onboarding
NOTES:          UX fix: add "you'll need your phone" text before QR renders.
```

---

## RECON-X-005

```
ID:             RECON-X-005
TYPE:           friction
TITLE:          noVNC browser viewer — undiscovered by most users
SUMMARY:        XRPLClaw agents run a headed Chrome browser on a virtual display. Users can watch the agent browse the web in real-time via a noVNC link on the dashboard. This capability is not surfaced prominently and goes undiscovered by the majority of users.
KEY_INSIGHT:    The live browser viewer is a significant differentiator — most agent platforms are black-box. Surfacing it early in onboarding converts passive users into engaged ones who understand the agent's full capability.
CATEGORY:       friction
TAGS:           xrplclaw, novnc, browser, visibility, onboarding, discovery, capability
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     7
FREQUENCY:      1
PRIORITY:       7.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-P-005
CHAIN:          none
TOOL:           xrplclaw
USE_CASE:       onboarding
NOTES:          Discovery friction — not a bug, underpromoted. Should be in the first-run experience.
```
