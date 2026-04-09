# Recon Collection — XRPL Failures
> File: failures/xrpl_failures_001.md | Schema: v2 | Created: 2026-04-09
> Entries: RECON-F-001 through RECON-F-005

---

## RECON-F-001

```
ID:             RECON-F-001
TYPE:           failure
TITLE:          AMM vs DEX slippage calculation mismatch — wrong formula applied
SUMMARY:        Builders frequently reuse DEX slippage logic for AMM swaps or vice versa, producing incorrect estimates that lead to unexpected fills or rejected transactions. DEX slippage is discrete — you read the order book, sum available quantity at each price level, and compute fill cost explicitly. AMM slippage is continuous and governed by the constant-product formula: output = (pool_y * input) / (pool_x + input), where pool_x and pool_y are current reserves. A 1% slippage estimate computed from the DEX order book will be wrong when applied to an AMM of different depth — sometimes dramatically so in thin pools.
KEY_INSIGHT:    Before any swap, determine whether you are routing through the DEX or an AMM (check AMMInfo for the pair). If AMM: use the constant-product formula with current pool reserves from AMMInfo to compute expected output, then derive your slippage tolerance from that. If DEX: read book_offers and sum fills. Do not share slippage code between the two — they are mathematically different systems.
CATEGORY:       failure
TAGS:           xrpl, amm, dex, slippage, formula, trading-bot, bug, defi, calculation
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      2
PRIORITY:       11.4
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-006, RECON-T-005, RECON-T-013, RECON-T-014
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       trading, development
NOTES:          Expanding RECON-T-006 (AMM entry) into a full failure record. Frequency set to 2 because this failure was first identified as a pattern risk in RECON-T-006 and is a known recurring bot failure. Fix: write two separate slippage functions, one for each venue. Test both against known pool states before deploying. Add a venue-detection step at the start of any swap execution path.
```

---

## RECON-F-002

```
ID:             RECON-F-002
TYPE:           failure
TITLE:          Reserve undercount causing tecINSUFFICIENT_RESERVE errors
SUMMARY:        XRPL accounts must maintain a minimum XRP reserve: 1 XRP base reserve + 0.2 XRP per owned object (trust lines, offers, escrows, NFT pages, etc.). Builders frequently forget to include all object types in their reserve calculation, particularly AMM LP token trust lines (each costs 0.2 XRP), NFTokenPages (2 XRP each), and open offers. A transaction fails with tecINSUFFICIENT_RESERVE if it would reduce spendable XRP below the required reserve. This error is especially disruptive in automated bots where it causes cascading failures — the bot retries the failed transaction, reserve stays the same, and every subsequent attempt fails.
KEY_INSIGHT:    Query account_info before submitting any transaction that creates a new ledger object (trust line, offer, escrow, NFT). Check: spendable XRP = account balance − (base_reserve + (object_count × incremental_reserve)). If spendable XRP after the new object would be less than the transaction fee + a safety buffer (recommend 1 XRP), stop and alert instead of transacting. Never assume reserve from a previous check — object count changes with every filled offer.
CATEGORY:       failure
TAGS:           xrpl, reserve, tecinsufficientreserve, trustline, offer, escrow, nft, bot, error
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      2
PRIORITY:       11.4
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-002, RECON-T-003, RECON-T-005, RECON-T-006, RECON-T-019
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       development, trading
NOTES:          Reserve values (base and incremental) can change via amendment — always read current values from server_info or account_info rather than hardcoding. As of 2025, base reserve = 1 XRP, incremental = 0.2 XRP — but these were 20 XRP and 5 XRP as recently as 2021. Any hardcoded legacy value will undercount dramatically. Frequency set to 2 because reserve errors are a known recurring pattern across XRPL bot builders, also linked to RECON-T-002.
```

---

## RECON-F-003

```
ID:             RECON-F-003
TYPE:           failure
TITLE:          Trust line not set before payment — tecNO_LINE or tecPATH_DRY failure
SUMMARY:        Sending a non-XRP token to an account that has not set a trust line for that token fails with tecNO_LINE (direct payment) or tecPATH_DRY (cross-currency path). This is the single most common payment failure in XRPL integrations. New users expect token transfers to work like XRP transfers; builders who onboard token recipients forget to verify the trust line exists first. The failure also occurs in automated flows when an account's trust line is at its set limit — the limit is not auto-raised.
KEY_INSIGHT:    Before sending any token payment, call account_lines on the destination and verify: (1) a trust line for the token's currency+issuer pair exists, and (2) the trust line's limit minus current balance is greater than the amount being sent. If the trust line is missing, prompt the recipient to add it before sending — or build a trust line pre-check into your payment flow with a clear user-facing error.
CATEGORY:       failure
TAGS:           xrpl, trustline, tecno-line, tecpath-dry, payment, token, integration, onboarding, bug
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      2
PRIORITY:       11.4
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-003, RECON-T-004, RECON-T-015, RECON-T-002, RECON-F-002
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py, Xaman
USE_CASE:       development, onboarding
NOTES:          Frequency set to 2 because this failure appears in both the trust line foundations entry (RECON-T-003) and is a universally reported issue in XRPL builder communities. The fix is simple and cheap: one account_lines query before sending. Build it into every token payment function as a pre-flight check. Consider wrapping it in a helper: checkTrustLine(account, currency, issuer) → {exists: bool, available: bigint}.
```

---

## RECON-F-004

```
ID:             RECON-F-004
TYPE:           failure
TITLE:          Bridge latency not handled in UX — users assume failed transactions
SUMMARY:        The XRPL ↔ XRPL EVM bridge (Axelar-based) takes 1–5 minutes for cross-chain transfers to complete. Users and builders who do not account for this latency experience "stuck" transactions that appear to fail. Common failure modes: (1) UX shows a spinner with no status update, user refreshes or submits again causing duplicate requests; (2) bot or backend logic times out after 30 seconds and marks the transfer as failed, then retries — creating double-transfer bugs; (3) user support tickets spike around bridge usage because the wait is unexpected.
KEY_INSIGHT:    Never treat bridge silence as failure — always implement a polling loop with explicit timeout of at least 10 minutes. Relay the transaction hash to the destination chain explorer URL immediately on submission, so users can independently verify status. Show a progress indicator with expected wait time (1–5 min) rather than an indeterminate spinner. Set retry logic to check for existing in-flight transfers before re-submitting.
CATEGORY:       failure
TAGS:           xrpl, bridge, axelar, evm, latency, ux, timeout, polling, cross-chain
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-012, RECON-T-009, RECON-T-011
CHAIN:          multi
TOOL:           XRPL EVM Bridge, Axelar
USE_CASE:       development
NOTES:          The bridge uses Axelar for cross-chain message passing. Track transaction status via Axelarscan (axelarscan.io) using the source chain tx hash. Bridge status endpoint is available from the Axelar SDK — poll every 15 seconds with exponential backoff. UX best practice: a "View on Axelarscan" link immediately on submission resolves 80% of user confusion before it becomes a support request.
```

---

## RECON-F-005

```
ID:             RECON-F-005
TYPE:           failure
TITLE:          Rate limiting on public XRPL nodes causing bot failures
SUMMARY:        Public XRPL nodes (s1.ripple.com, s2.ripple.com, and community-hosted nodes) enforce rate limits on WebSocket and JSON-RPC connections. Bots that submit bursts of transactions or run continuous subscriptions hit these limits and receive connection drops, 429-equivalent responses (in WebSocket: error frames), or silent disconnections that the bot interprets as successful submission. This leads to missed fills, lost subscription events, and ghost transactions — especially during market volatility when all bots are most active simultaneously.
KEY_INSIGHT:    Never run production trading bots against public XRPL nodes. Use a private node endpoint — on XRPLClaw, use ws://xrpl-rpc.goons.app:51238 (WebSocket) or http://xrpl-rpc.goons.app:51233 (JSON-RPC). Implement reconnection logic with exponential backoff on all WebSocket clients — treat any disconnect as potentially silent and re-subscribe to confirm state. Always verify transaction submission by querying transaction hash status separately from the submission response.
CATEGORY:       failure
TAGS:           xrpl, rate-limit, public-node, websocket, bot, production, infrastructure, reliability
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-008, RECON-T-001, RECON-F-001, RECON-F-002
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       trading, development
NOTES:          xrplclaw private nodes have zero rate limits for platform users. For projects deployed outside the platform, Dhali (RECON partners context) provides pay-per-request XRPL API access without rate limits. Implement tx.submit() + tx.getTransaction() as a two-step pattern: submit, get a preliminary result, then poll getTransaction(hash) until validated:true before treating as confirmed. Never trust the submit response alone — a rate-limited node may acknowledge locally and then fail to broadcast.
```
