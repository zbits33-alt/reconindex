# Collection: XRPL Foundations
> File: tools/xrpl_foundations_001.md | Schema: v2 | Date: 2026-04-09
> Source: Official XRPL documentation (xrpl.org) — Tier 1 primary reference
> Purpose: Foundation knowledge for Society Libraries — XRPL Foundations bucket

---

## RECON-T-001

```
ID:             RECON-T-001
TYPE:           platform
TITLE:          XRPL mainnet — what it is and how it works
SUMMARY:        The XRP Ledger (XRPL) is a decentralized public blockchain with a native asset (XRP) and built-in primitives: accounts, payments, a native DEX, AMMs, token issuance, and trust lines. It uses a consensus protocol (not proof-of-work) with a validator network. Transactions settle in 3–5 seconds with finality. No smart contracts on mainnet — functionality lives in ledger-native transaction types.
KEY_INSIGHT:    XRPL is not EVM. Functionality is built into the protocol itself via transaction types — not smart contracts. This is a fundamental mental model shift for Ethereum builders and the #1 source of XRPL onboarding confusion.
CATEGORY:       onboarding
TAGS:           xrpl, mainnet, blockchain, consensus, accounts, payments, dex, amm, tokens
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-002, RECON-T-003, RECON-T-007
CHAIN:          xrpl
TOOL:           xrpl
USE_CASE:       onboarding
NOTES:          Foundation entry for XRPL Foundations bucket. Must be first.
```

---

## RECON-T-002

```
ID:             RECON-T-002
TYPE:           platform
TITLE:          XRPL accounts and reserves — how they work
SUMMARY:        Every XRPL account requires a base reserve of XRP (currently 10 XRP) to exist on ledger. Additional reserves are required per object owned: trust lines, offers, escrows, etc. (currently 2 XRP each). These reserves are locked — not spent — and released if the object is deleted. Accounts are created by sending at least the base reserve to a new address.
KEY_INSIGHT:    Reserves are the #1 surprise for new XRPL users and builders. Failing to account for reserves causes "not enough XRP" errors that appear to be bugs but are actually protocol behavior. Every application handling new wallets must reserve-aware from day one.
CATEGORY:       onboarding
TAGS:           xrpl, accounts, reserves, base-reserve, owner-reserve, xrp, wallet
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-001, RECON-T-003
CHAIN:          xrpl
TOOL:           xrpl
USE_CASE:       onboarding
NOTES:          Reserve values are subject to governance vote. Always reference current values from live ledger state, not hardcoded docs.
```

---

## RECON-T-003

```
ID:             RECON-T-003
TYPE:           platform
TITLE:          XRPL trust lines — what they are and why they matter
SUMMARY:        Trust lines are ledger objects that allow an account to hold tokens issued by another account. A trust line must exist before a token can be received. Each trust line has a limit (how much the holder trusts the issuer) and a balance. Trust lines consume owner reserve (2 XRP each). Rippling behavior determines how trust lines interact in multi-hop payments.
KEY_INSIGHT:    Trust lines are the gating mechanism for all token usage on XRPL. Any application involving issued tokens — including stablecoins like RLUSD — requires trust line setup before tokens can be received. Missing trust line = payment failure.
CATEGORY:       onboarding
TAGS:           xrpl, trust-lines, tokens, issued-tokens, rippling, rlusd, stablecoin
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-001, RECON-T-002, RECON-T-004
CHAIN:          xrpl
TOOL:           xrpl
USE_CASE:       onboarding
NOTES:          Rippling behavior is complex — separate entry needed. Trust line limit of 0 is valid and useful for blocking unwanted tokens.
```

---

## RECON-T-004

```
ID:             RECON-T-004
TYPE:           platform
TITLE:          XRPL token issuance — how to issue tokens
SUMMARY:        Any XRPL account can issue tokens by sending them to accounts that have established trust lines. Tokens are identified by currency code (3-char or 20-byte hex) + issuer address. The issuer can set flags: transfer fees, freeze capability, require authorization, no-ripple. Token supply is controlled entirely by the issuer — there is no smart contract governing it.
KEY_INSIGHT:    XRPL token issuance requires no smart contract — it is a native protocol feature. The issuer account IS the token contract. This is far simpler than ERC-20 but requires understanding of trust lines, rippling, and issuer account security (cold/warm/hot wallet architecture).
CATEGORY:       tools
TAGS:           xrpl, tokens, issuance, currency-code, issuer, freeze, transfer-fee, hot-wallet, cold-wallet
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-003, RECON-T-005
CHAIN:          xrpl
TOOL:           xrpl
USE_CASE:       development
NOTES:          Issuer account security is critical — if the issuer is compromised, the token is compromised. Cold/warm/hot wallet pattern is the standard mitigation.
```

---

## RECON-T-005

```
ID:             RECON-T-005
TYPE:           platform
TITLE:          XRPL DEX — native decentralized exchange
SUMMARY:        XRPL has a built-in DEX using an order book model. Offers are ledger objects — placing an offer creates an on-ledger record. The DEX supports cross-currency payments via pathfinding, where the ledger automatically finds the best route through existing offers. Auto-bridging through XRP reduces fragmentation across currency pairs. Tick size and transfer fees affect pricing precision.
KEY_INSIGHT:    The XRPL DEX is not a separate protocol or smart contract — it is part of the ledger itself. Every account can place offers. Pathfinding is built in. This makes XRPL one of the only blockchains where a cross-currency payment and a DEX trade are the same operation.
CATEGORY:       tools
TAGS:           xrpl, dex, orderbook, offers, pathfinding, auto-bridging, cross-currency, tick-size
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-001, RECON-T-006
CHAIN:          xrpl
TOOL:           xrpl
USE_CASE:       trading
NOTES:          Auto-bridging through XRP is important for bot builders — pairs without direct liquidity may route through XRP automatically.
```

---

## RECON-T-006

```
ID:             RECON-T-006
TYPE:           platform
TITLE:          XRPL AMMs — automated market makers
SUMMARY:        XRPL has native AMMs (XLS-30 amendment) integrated with the DEX. Each AMM pool holds two assets and issues LP tokens to liquidity providers. The AMM uses a constant-product formula (x*y=k) for pricing. AMMs and the DEX orderbook are unified — pathfinding uses both. A trading fee is set per pool. Liquidity providers earn fees from trades.
KEY_INSIGHT:    XRPL AMM slippage math is constant-product (x*y=k) — NOT the same as DEX orderbook spread calculations. Applying orderbook slippage logic to AMM pools causes systematic pricing errors. This is a common and costly mistake for trading bot builders.
CATEGORY:       tools
TAGS:           xrpl, amm, liquidity, lp-tokens, constant-product, slippage, xls-30, trading-fee
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-005
CHAIN:          xrpl
TOOL:           xrpl
USE_CASE:       trading
NOTES:          AMM vs DEX slippage confusion is a confirmed high-impact pattern for bot builders. Links to future RECON-F entries on AMM pricing mistakes.
```

---

## RECON-T-007

```
ID:             RECON-T-007
TYPE:           platform
TITLE:          XRPL transaction types — the full capability map
SUMMARY:        XRPL functionality is expressed through transaction types, not smart contracts. Core types: Payment, OfferCreate, OfferCancel, TrustSet, AccountSet, EscrowCreate/Finish/Cancel, PaymentChannelCreate/Fund/Claim, NFTokenMint/Burn/Offer, AMMCreate/Deposit/Withdraw/Vote/Bid. Each type has specific required and optional fields. Amendments add new types over time.
KEY_INSIGHT:    Understanding the transaction type map IS understanding XRPL's capability surface. Every feature — DEX, AMMs, escrow, payment channels, NFTs — is a transaction type. Builders should map their use case to transaction types first, before looking for SDKs or libraries.
CATEGORY:       tools
TAGS:           xrpl, transactions, transaction-types, payment, offer, trustset, escrow, nft, amm, amendments
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-001, RECON-T-005, RECON-T-006
CHAIN:          xrpl
TOOL:           xrpl
USE_CASE:       development
NOTES:          Amendment awareness matters — new transaction types only activate after validator supermajority. Always check amendment status before building on newer features.
```

---

## RECON-T-008

```
ID:             RECON-T-008
TYPE:           platform
TITLE:          XRPL SDKs and API access — builder entry points
SUMMARY:        Primary SDKs: xrpl.js (JavaScript/TypeScript, most active), xrpl-py (Python). Both support wallet creation, transaction signing, WebSocket subscriptions, and all transaction types. API access via WebSocket (real-time) or JSON-RPC (request-response). Public nodes available but rate-limited. Private nodes (like XRPLClaw's private CLIO endpoints) offer zero rate limits.
KEY_INSIGHT:    xrpl.js is the most actively maintained SDK and has the best coverage of new features. For production bots and applications, private node access is non-negotiable — public nodes will rate-limit under any meaningful load.
CATEGORY:       tools
TAGS:           xrpl, sdk, xrpl-js, xrpl-py, websocket, json-rpc, clio, private-node, api
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-001, RECON-T-007
CHAIN:          xrpl
TOOL:           xrpl, xrpl-js, xrpl-py
USE_CASE:       development
NOTES:          XRPLClaw provides private CLIO + WebSocket endpoints at zero rate limits — key advantage for agents on the platform.
```
