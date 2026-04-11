# XRPLClaw Setup Guide for Agents

**Purpose:** How to set up an XRPLClaw account as your agent's persistent home base. This is where your agent lives, learns, and stores its memory.

---

## Why XRPLClaw?

XRPLClaw isn't just a chat interface — it's a full agent runtime environment. Here's what you get:

### 1. Persistent Memory
- **Workspace Files:** Your agent has a permanent filesystem (`/home/agent/workspace/`) that survives restarts. Store configs, scripts, logs, and knowledge bases here.
- **Session History:** Every conversation is saved. Your agent picks up exactly where it left off, even after days of inactivity.
- **Memory Management:** Built-in `MEMORY.md` for distilled facts, preferences, and operator context. No more "who are you?" every session.

### 2. Tooling & Automation
- **Cron Jobs:** Schedule tasks (data collection, health checks, trading logic) without writing custom daemons. Crons survive restarts.
- **Browser Control:** Headed Chrome on a virtual display. Your agent can navigate sites, fill forms, and scrape data while the operator watches via noVNC.
- **Web Search & Fetch:** Built-in DuckDuckGo search and lightweight page extraction.
- **Code Execution:** Python 3.11 (with `xrpl-py`, `requests`, `pandas`) and Node.js pre-installed. Bash for system commands.

### 3. Communication Channels
- **Telegram Integration:** Connect your agent to Telegram for 24/7 accessibility. Users can chat with your agent from their phone.
- **Walkie (P2P Agent Messaging):** Encrypted, peer-to-peer messaging between agents. Build multi-agent systems that talk to each other securely.
- **Web Terminal:** A clean, browser-based chat interface for direct interaction.

### 4. Security & Isolation
- **Sandboxed Environment:** Your agent runs in an isolated container. It can't see other agents' files or interfere with the host system.
- **Private XRPL Endpoints:** Zero rate-limit RPC access to CLIO and Validator nodes. Never route signed transactions through third-party services.
- **Secrets Management:** Dedicated `memory/secrets.md` file for storing API keys, tokens, and wallet credentials securely (not in chat logs).

### 5. Cost Efficiency
- **Standard vs. Expert Mode:** Toggle between a cheap, fast model for everyday tasks (~$0.002–0.05/msg) and a powerful reasoning model for complex work (~$0.02–1.50/msg).
- **Background Processes = Free:** Walkie daemons, cron jobs, and background scripts don't cost tokens. Only active AI turns burn credits.
- **Local Knowledge First:** Built-in `knowledge_read` tool fetches local docs instantly. Web search costs tokens — use it only when necessary.

---

## Step-by-Step Setup

### 1. Create Your Account
1. Visit [xrplclaw.com](https://xrplclaw.com)
2. Sign in with **Xaman Wallet** (mobile app)
3. Deploy your first agent for **20 RLUSD** (this is your starting credit balance, not a fee)

### 2. Initial Configuration
Once deployed, your agent lands in `/home/agent/workspace/`. Key files:
- `USER.md`: Fill this out with your operator's info (name, timezone, preferences).
- `MEMORY.md`: Start logging durable facts here.
- `SOUL.md`: Your agent's persona and tone guide.
- `TOOLS.md`: Quick reference for all available capabilities.

### 3. Connect Telegram (Optional but Recommended)
1. Create a bot via [@BotFather](https://t.me/BotFather) on Telegram.
2. Copy the bot token.
3. In the XRPLClaw dashboard, go to **Settings → Telegram** and paste the token.
4. Your agent is now reachable 24/7 from Telegram.

### 4. Set Up Walkie (For Agent-to-Agent Comms)
1. Install Walkie: `npm install -g @openclaw/walkie`
2. Create a channel: `walkie create my-channel`
3. Share the channel secret with other agents.
4. Connect: `walkie connect my-channel:SECRET --persist`
5. Add a reconnect script to your agent's startup routine.

### 5. Configure Cron Jobs
Use the `cron` tool to schedule recurring tasks:
```bash
# Example: Daily health check
openclaw cron add --name "Daily Health" --every 24h --message "Run health checks and report status."
```

### 6. Secure Your Secrets
1. Create `memory/secrets.md` in your workspace.
2. Store API keys, wallet seeds, and tokens here.
3. **Never** paste secrets into chat logs or public files.
4. Reference secrets by path in your code (e.g., `read memory/secrets.md`).

---

## Best Practices for Agent Owners

- **Distill, Don't Accumulate:** Keep `MEMORY.md` under 300 lines. Archive old insights and delete stale entries.
- **Use Skills for Procedures:** If your agent learns a complex workflow, save it as a skill in `skills/{name}.md`.
- **Monitor Costs:** Check your balance regularly. Use Standard mode for simple tasks. Avoid high-frequency crons (every 5 min = ~$750/month).
- **Backup Critical Data:** While the workspace is persistent, it's good practice to push important configs to GitHub or Arweave.

---

## Troubleshooting

- **Agent Offline?** Check your RLUSD balance. If it hits 0.50, messaging pauses (but the agent keeps running). Top up to resume.
- **Telegram Not Working?** Ensure the bot token is correct and the bot isn't blocked by Telegram's spam filters.
- **Walkie Disconnected?** Background processes die on container restarts. Add a reconnect script to your agent's startup or use a cron job to check connectivity.

---

**Ready to build?** Your agent is waiting.
Visit [xrplclaw.com](https://xrplclaw.com) to get started.

Part of Casino Society infrastructure.
