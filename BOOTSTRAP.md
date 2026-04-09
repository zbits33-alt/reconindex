# Workspace Index

**IMPORTANT:** Before starting any task, identify which topics below are relevant and fetch them using the `knowledge_read` tool.

## Knowledge Base

Use `knowledge_read` with the file path to fetch any document below. These are served from the centralized knowledge server — not local files.

<!-- kb:start -->
### crypto/
| File | Read When |
|------|-----------|
| XRPL_REFERENCE | Protocol, accounts, reserves, fees, consensus, tx lifecycle, API methods, result codes |
| XRPL_TOKENS | Trust lines, issuance, clawback, MPTs, credentials, DIDs, freezing, rippling, payments |
| XRPL_DEX | DEX orderbook, AMMs, pathfinding, auto-bridging, tick size, price oracle |
| XRPL_ADVANCED | Multi-signing, escrow, payment channels, NFTs (XLS-20), amendments, sidechains |
| XRPL_CODE_EXAMPLES | xrpl.js v4 + xrpl-py: wallet, payments, DEX, AMM, NFTs, multi-sign, subscriptions |
| XRPLEVM_REFERENCE | XRPL EVM sidechain: Solidity, bridging, Foundry, ethers.js/viem, DeFi |
| AXELAR_BRIDGE | Bridging XRP/IOUs between XRPL and XRPL EVM: memo format, gas, code examples |
| FLARE_REFERENCE | Flare dev, FLR, FTSO oracles, FAssets, State Connector |
| FLARE_COMMUNITY | Flare community, key figures, ecosystem projects |
| SONGBIRD_REFERENCE | Songbird dev, SGB, canary network, Coston testnet |
| SONGBIRD_COMMUNITY | Songbird community, SGB holders, ecosystem |
| COREUM_REFERENCE | Coreum dev, Smart Tokens, WASM, Cosmos SDK |
| COREUM_COMMUNITY | Coreum community, rebranding, XRPL connection |
| XAHAU_REFERENCE | Xahau L1, XAH, Hooks smart contracts, governance |
| EVERNODE_REFERENCE | Evernode dev, HotPocket, EVR token, decentralized hosting |
| EVERNODE_COMMUNITY | Evernode community, host operators |
| XAMAN_AUTH | Xaman wallet auth, payments, OAuth2 PKCE, deep linking, payloads |
| JOEY_WALLET | Joey SDK, WalletConnect v2, QR connect, XRPL payments, dApp browser |
| PRIVY_REFERENCE | Privy embedded wallets, social login, server-side verification |
| PRIVY_XRPLEVM_AUTH | Privy on XRPL EVM: chain config, PrivyProvider, production gotchas |
| METAMASK_REFERENCE | MetaMask SDK, EVM integration, Snaps, smart accounts |
| TRADING_GUIDE | Trading wallets, SetRegularKey, DEX bots, cost-smart patterns |
| MARKET_DATA | Token prices, briefing.json schema, technical indicators |
| TOKEN_REGISTRY | XRPL token lookup — resolve names to issuer addresses |
| ARWEAVE_REFERENCE | Arweave storage, Turbo SDK, AO compute, uploads, gateways |
| ARWEAVE_NFT_IMAGES | NFT images from Arweave, gateway load-balancing, caching |

### webdev/
| File | Read When |
|------|-----------|
| HOSTING_GUIDE | Deploying sites, serving files, making things live, quick tunnels, Cloudflare Pages, Vercel, domains — MUST read before any deploy |
| UX_PATTERNS | Loading states, error display, user feedback — read before building any UI |
| PORKBUN_API | Porkbun API — domains, DNS records, SSL |
| TELEGRAM_MINI_APPS | TMAs: SDK v3, initData auth, Stars payments, TON Connect |
| TELEGRAM_BOTS | grammY, Telegraf, webhooks, sessions, inline mode, payments |
| DISCORD_BOTS | discord.js, slash commands, gateway intents, voice, sharding |
| DISCORD_APPS | Embedded App SDK, Rich Presence, OAuth2, linked roles |
| WALKIE_A2A | P2P agent messaging, Hyperswarm, multi-agent comms (platform-endorsed) |

### platform/
| File | Read When |
|------|-----------|
| GETTING_STARTED | What is XRPLClaw, first steps, onboarding, what you can build |
| TELEGRAM_SETUP | Connecting Telegram, bot token, @BotFather, troubleshooting |
| BILLING_GUIDE | How billing works, Standard vs Expert costs, topping up |
| WORKSPACE_GUIDE | Agent capabilities, channels, Standard vs Expert mode, dashboard |
| TROUBLESHOOTING | Common issues: Telegram, balance, agent offline, payments |
| SUPPORT_PROTOCOL | Billing, account, or platform issues |
| ARCHITECTURE_PUBLIC | How the platform works, tech stack, building your own |
| BRAND_ASSETS | SVG logos for XRPL ecosystem — fetch via `asset_read` |
| XRPLCLAW_BRANDING | XRPLClaw logos, embed snippets, referral system |
| PARTNER_PROGRAM | Referral program, partnership opportunities |
| PROJECT_DOCS | Complex projects — living documentation pattern (CLAUDE.md + PLAN.md), surviving compactions |

### partners/
| File | Read When |
|------|-----------|
| BLUME_FINANCE | Blume DeFi on XRPL EVM — BlumeSwap, Blumepad, BlumePerps, BlumeLend |
| DHALI_API | x402 protocol, pay-per-request XRPL APIs via payment channels |
<!-- kb:end -->
<!-- last synced: 2026-04-08T02:56:19Z -->

> Auto-syncs every 5 min. Topic not listed? Use `knowledge_search("your topic")` to search all docs.

## Live Data

| File | Source | Read When |
|------|--------|-----------|
| `state/market/briefing.md` | Market service (every 3 min) | Market prices, XRP ecosystem, technicals, macro, news — read this FIRST for any market question |
| `state/market/briefing.json` | Market service (every 3 min) | Programmatic access to market data, detailed analysis, historical comparisons |
| `state/market/price-log.csv` | Market service (appended) | Price trend analysis, historical data (rolling 2000 rows, ~4 days) |

## Skills (Procedural Memory)

Before starting a complex task, run `ls skills/` to check for existing procedures. Read any relevant skill file before reinventing a workflow. After completing a novel multi-step task, create a new skill — see `skills/_README.md` for format.

## Operational Files

| File | Read When |
|------|-----------|
| `HEARTBEAT.md` | Periodic maintenance — runs automatically on idle |
| `ONBOARDING.md` | `USER.md` doesn't exist (first interaction only) |
