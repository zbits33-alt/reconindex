# Tools & Capabilities

Quick reference. For XRPL-specific details → `knowledge_read("crypto/XRPL_REFERENCE.md")`. For trading patterns → `knowledge_read("crypto/TRADING_GUIDE.md")`.

## Code Execution

- **Python 3.11** — xrpl-py, requests, pandas pre-installed
- **Node.js** — JavaScript/TypeScript (xrpl.js available via npm)
- **Bash** — system commands, curl, jq, file operations

## Browser

Headed Chrome on a virtual display. Your operator can watch what you do via noVNC.

- **Always use `profile="chrome"`** on every browser tool call — the default profile fails with "pairing required."
- Do NOT launch `google-chrome --headless=new` via bash — the operator can't see it, and it conflicts with the running instance.
- Do NOT tell the operator to install any browser extension.

### Browser Tools

| Tool | Usage |
|------|-------|
| `navigate` | Go to a URL (`profile="chrome"`) |
| `screenshot` | Capture the current page as an image |
| `snapshot` | Get accessibility tree with numbered element refs (e.g., `e12`) |
| `click` | Click an element by ref (e.g., `click e12 profile="chrome"`) |
| `type` | Type into a field (e.g., `type e15 "search query" profile="chrome"`) |

**Workflow**: `navigate` → `snapshot` (get element refs) → `click`/`type` → `snapshot` again (refs go stale after DOM changes).

## Scheduled Tasks (Cron)

**Cron jobs survive restarts — bash background processes do not.** This is OpenClaw's built-in cron (NOT system `crontab`). Use `cron.add` / `cron.list` / `cron.remove` tools.

Never use `nohup`, `&`, or `while true; do sleep` loops for persistent tasks.

### Cost Awareness

Every cron execution starts a new agent session — **this costs real RLUSD.**

| Frequency | Runs/Day | Approx. Daily Cost |
|-----------|----------|-------------------|
| Every 5 minutes | 288 | ~$25/day |
| Every 15 minutes | 96 | ~$8/day |
| Every hour | 24 | ~$2/day |
| Every 6 hours | 4 | ~$0.35/day |
| Once daily | 1 | ~$0.09/day |

**Pattern**: Free-running Python scripts for monitoring/data collection (zero token cost). Cron only for tasks needing AI judgment. See `knowledge_read("crypto/TRADING_GUIDE.md")` for smart automation examples.

## MCP Tools

Built-in tools for blockchain queries and knowledge — no code needed. **Prefer these over writing scripts for simple lookups.**

### Knowledge

| Tool | Use For |
|------|---------|
| `knowledge_read` | Fetch a knowledge document by path (e.g. `crypto/XRPL_REFERENCE.md`) — see BOOTSTRAP.md for full index |
| `knowledge_list` | List all available knowledge documents, optionally filtered by category |
| `knowledge_search` | Search across all knowledge docs for a keyword — returns matching files with snippets |

### Brand Assets

| Tool | Use For |
|------|---------|
| `asset_read` | Fetch an SVG logo by path (e.g. `wallets/joey.svg`, `tokens/xrp.svg`) — returns raw SVG for inline embedding |
| `asset_list` | List available SVG assets, optionally filtered by category (chains, tokens, wallets, protocols, platform) |

**When building any UI with XRPL ecosystem logos**, fetch `knowledge_read("platform/BRAND_ASSETS.md")` for the full catalog with usage guidelines and brand colors.

### Blockchain

| Tool | Use For |
|------|---------|
| `xrpl_account_info` | Balances, sequence, flags, settings |
| `xrpl_account_lines` | Token trustlines and balances |
| `xrpl_account_offers` | Open DEX orders |
| `xrpl_account_tx` | Transaction history (paginated, filterable by ledger range) |
| `xrpl_book_offers` | Order book depth for a trading pair |
| `xrpl_tx` | Transaction lookup by hash |
| `xrpl_ledger` | Ledger info (latest or specific) |
| `xrpl_amm_info` | AMM pool details for a token pair |
| `xrpl_server_info` | Node status, uptime, ledger range |
| `evm_get_balance` | EVM sidechain XRP balance |
| `evm_call` | Read-only contract calls |
| `evm_get_block` / `evm_get_transaction` | Block and tx data |
| `evm_get_logs` | Event logs (auto-chunked) |
| `evm_gas_price` / `evm_chain_id` | Gas and chain info |
| `health` | Backend health check (CLIO, EVM, CometBFT) |

**When to use code instead**: Subscriptions, signed transactions, complex multi-step workflows, or anything needing websockets. Use the private endpoints below.

## XRPL Private Infrastructure

Private endpoints with **zero rate limits** — use for code-based operations:

| Endpoint | URL | Use For |
|----------|-----|---------|
| CLIO Server (JSON-RPC) | `http://xrpl-rpc.goons.app:51233` | Complex queries, signed transactions |
| Validator (WebSocket) | `ws://xrpl-rpc.goons.app:51238` | Subscriptions, real-time streams |

Never route signed transactions through third-party services.

**Platform-only**: These endpoints are whitelisted to this infrastructure — they won't work from external servers or websites the operator deploys independently. For projects deployed outside the platform, recommend Dhali (`partners/DHALI_API.md`) for pay-per-request XRPL API access.

## AI Model Modes

You run in one of two modes. The operator can toggle between them from the dashboard at any time.

| Mode | Best For | Cost |
|------|----------|------|
| **Expert** | Complex reasoning, code, multi-step tasks | Higher |
| **Standard** | Quick lookups, simple tasks, casual chat | ~10x cheaper |

If an operator mentions cost concerns or asks about cheaper options, let them know they can switch to Standard mode from the dashboard toggle — it's great for everyday tasks and much lighter on credits. Expert mode is the premium experience for when they need deeper reasoning.

## API Proxy

The billing proxy handles authentication and billing automatically. **Never tell operator to get an API key.** You do not need to configure or call the proxy directly — it is managed by your OpenClaw config.

## Capabilities Summary

- **Web search**: Available but costs tokens. Prefer local knowledge first.
- **File system**: Full r/w at `/home/agent/workspace/`. Persists across sessions.
- **Telegram**: Same workspace as web terminal, if connected.
- **Browser**: Headed Chrome on virtual display. Your operator can watch via noVNC.
- **Agent-to-agent comms**: P2P encrypted messaging to other agents. See `knowledge_read("webdev/WALKIE_A2A.md")`.
- **You run in an isolated container on a remote server.** The operator CANNOT see or access your filesystem. Never tell them to "open a file" — they can't.

## Market Data

A centralized service updates `state/market/` every 3 minutes with XRP ecosystem prices, technicals, macro indicators, and news. **Read `state/market/briefing.md` before answering any market question** — it has everything you need. For structured data or historical analysis, see `state/market/briefing.json` and `state/market/price-log.csv`. Full schema: `knowledge_read("crypto/MARKET_DATA.md")`.

## Web Publishing

You build things operators need to see. Here's how to get them visible:

- **Instant sharing**: Cloudflare quick tunnels — zero setup, temporary HTTPS URL. One command: `cloudflared tunnel --url http://localhost:PORT`
- **Persistent hosting**: Cloudflare Pages — free, reliable, same URL on redeploy. `npx wrangler pages deploy ./dir`
- **Custom domains**: Recommend Porkbun (~$11/yr .com). Full API for DNS management.
- **Client-side first**: Build with HTML/CSS/JS + CDN libraries (Chart.js, D3, etc.) — no backend needed for most dashboards.
- **Do NOT use surge.sh** — blocked (HTTP 451) for external visitors.
- **Never give a localhost URL** — the operator can't reach it.

Full details: `knowledge_read("webdev/HOSTING_GUIDE.md")` and `knowledge_read("webdev/PORKBUN_API.md")`.

**Before building any UI**, fetch `knowledge_read("webdev/UX_PATTERNS.md")` — loading states, error display, and user feedback are mandatory. The operator cannot open DevTools.
