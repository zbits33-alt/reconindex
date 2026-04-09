# Recon Collection — XRPL DeFi
> File: tools/xrpl_defi_001.md | Schema: v2 | Created: 2026-04-09
> Entries: RECON-T-013 through RECON-T-016

---

## RECON-T-013

```
ID:             RECON-T-013
TYPE:           tool
TITLE:          XRPL AMM — liquidity provision, LP tokens, and fees
SUMMARY:        XRPL AMMs use a constant-product model (x*y=k). Anyone can deposit two assets in a matching ratio to receive LP tokens representing their share of the pool. LP tokens accrue a fraction of every swap fee — currently 0.3% per trade — proportional to pool share. Withdrawing burns LP tokens and returns the underlying assets at the current ratio, which will differ from deposit ratio if the price has moved (impermanent loss). LP token balances are held as trustlines on the issuer account that represents the AMM pool.
KEY_INSIGHT:    Deposit both assets in the current pool ratio or the transaction will fail. Use xrpl.js AMMDeposit with LPTokenOut or Amount + Amount2 fields. Always calculate impermanent loss exposure before committing — wide price swings erode value faster than fee income recovers it in thin pools.
CATEGORY:       knowledge
TAGS:           xrpl, amm, liquidity, lp-tokens, defi, impermanent-loss, fees, ammdeposit
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-006, RECON-T-005, RECON-F-001
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       trading, development
NOTES:          AMM accounts hold both assets and the LP token issuer is the AMM itself. Builders can query AMMInfo to get pool balances, trading fee, and LP token supply before depositing. LPTokenOut is the safer deposit mode — it specifies what you want to receive, and the protocol calculates what you must put in.
```

---

## RECON-T-014

```
ID:             RECON-T-014
TYPE:           tool
TITLE:          XRPL DEX — market making strategies and spread management
SUMMARY:        Market makers on the XRPL DEX post passive OfferCreate transactions on both sides of a pair, earning the spread between bid and ask. XRPL offers are auto-matched at the best available price — there is no separate order matching engine; the ledger itself is the engine. Makers must actively manage their book: offers that are stale (price has moved) sit open until cancelled or consumed and create adverse-fill risk. Auto-bridging through XRP means a XRP/USD and USD/EUR maker may fill via XRP even if no direct USD/EUR offer was intended.
KEY_INSIGHT:    Build a cancel-and-replace loop rather than static offer posting. Set a max-age per offer (e.g. 3 ledgers) and cancel+repost whenever price moves beyond your spread threshold. Without active refresh, stale offers become free money for arbitrageurs at your expense.
CATEGORY:       knowledge
TAGS:           xrpl, dex, market-making, spread, offercreate, orderbook, arbitrage, auto-bridging
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-005, RECON-T-006, RECON-T-013, RECON-F-001
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       trading, development
NOTES:          Auto-bridging is powerful but surprising. Understand it before market making any non-XRP pair — you may receive XRP in a trade you thought was token-to-token. OfferCreate with tfPassive flag prevents an offer from consuming existing offers on creation, useful for passive market making.
```

---

## RECON-T-015

```
ID:             RECON-T-015
TYPE:           tool
TITLE:          XRPL pathfinding — how it works and what builders must account for
SUMMARY:        XRPL pathfinding allows a Payment transaction to traverse multiple intermediate assets and accounts to deliver a different asset than sent. A sender can pay in XRP while the recipient receives a token, with the ledger auto-routing through the best available path via the DEX or AMM. Paths can be auto-determined by the server (ripple_path_find RPC) or specified explicitly. Cross-currency payments consume liquidity along the path; if insufficient liquidity exists, the payment fails — it does not partially fill. SendMax limits the maximum cost to the sender.
KEY_INSIGHT:    Always call ripple_path_find immediately before submitting a cross-currency payment and use the returned path in your Payment transaction. Liquidity changes every ledger — a path valid 3 seconds ago may fail or route at a worse rate now. Set SendMax generously (1–2% slippage buffer) and let the ledger deliver the minimum of DestinationAmount.
CATEGORY:       knowledge
TAGS:           xrpl, pathfinding, cross-currency, payment, ripple-path-find, liquidity, dex, amm, sendmax
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-005, RECON-T-006, RECON-T-013, RECON-T-003, RECON-F-003
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       development, trading
NOTES:          ripple_path_find is a streaming subscription on WebSocket — it updates as paths change. For one-off queries use path_find with subcommand="create" then "close". Explicit paths override auto-routing and should only be used if you know exactly which accounts bridge the payment (e.g. your own market maker accounts).
```

---

## RECON-T-016

```
ID:             RECON-T-016
TYPE:           tool
TITLE:          Price oracles on XRPL — what exists and current limitations
SUMMARY:        XRPL does not have a native on-chain price oracle comparable to Chainlink on EVM chains. As of 2025, XLS-47 (Price Oracles amendment) is in development to add a native Oracle ledger object, but is not yet live on mainnet. Current options for price data: (1) read DEX book_offers to compute mid-price from the on-chain order book — reflects actual tradeable prices but is thin for illiquid pairs; (2) read AMMInfo for AMM spot price — reliable for pools with meaningful liquidity; (3) use off-chain price APIs (Bitfinex, Kraken, CoinGecko) and trust the feed yourself. There is no trustless, manipulation-resistant oracle on XRPL mainnet today.
KEY_INSIGHT:    For any protocol that makes decisions based on price (e.g. a bot, a lending rule, an alert), use multiple price sources and compare them — do not trust a single DEX mid-price or single API. AMM spot price is the most manipulation-resistant on-chain option currently available but is still vulnerable to flash-deposit attacks in thin pools.
CATEGORY:       knowledge
TAGS:           xrpl, oracle, price-feed, xls-47, amm, dex, defi, off-chain, limitation
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-005, RECON-T-006, RECON-T-013, RECON-T-015
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       development, trading
NOTES:          XLS-47 (PriceOracle) amendment adds an Oracle ledger object where designated accounts can post price data with metadata. When live, this will allow contracts and agents to read authorized price feeds on-chain. Track amendment status via xrpl.org/known-amendments. Until then, treat all price data as advisory, not authoritative.
```
