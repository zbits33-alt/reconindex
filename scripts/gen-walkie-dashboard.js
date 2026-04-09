#!/usr/bin/env node
// Generates walkie-dashboard.html from ~/.walkie/messages/*.jsonl
// Run every 5 min via cron. Zero dependencies — pure Node.js.

const fs = require('fs');
const path = require('path');
const os = require('os');

const MESSAGES_DIR = path.join(os.homedir(), '.walkie', 'messages');
const OUTPUT = path.join(__dirname, '..', 'dashboard', 'walkie-dashboard.html');

function readJsonl(filePath) {
  if (!fs.existsSync(filePath)) return [];
  return fs.readFileSync(filePath, 'utf8')
    .split('\n')
    .filter(l => l.trim())
    .map(l => { try { return JSON.parse(l); } catch { return null; } })
    .filter(Boolean);
}

function formatTime(ts) {
  if (!ts) return '?';
  return new Date(ts).toISOString().replace('T', ' ').slice(0, 19) + ' UTC';
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function formatMessageText(text) {
  // Convert newlines and basic formatting for display
  let escaped = escapeHtml(text);
  // Bold: **text** → <strong>text</strong>
  escaped = escaped.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
  // Inline code: `code` → <code>code</code>
  escaped = escaped.replace(/`(.+?)`/g, '<code>$1</code>');
  // Newlines
  escaped = escaped.replace(/\n/g, '<br>');
  return escaped;
}

function getChannelLabel(channelName) {
  const labels = {
    'predator-collab': '🤝 Predator Collab',
    'recon-chat': '💬 Recon Chat',
    'recon-general': '🌐 Recon General',
    'xc-recon-eaf6': '🔗 Recon↔Predator (XC)',
    'xc-predator-126d': '🔗 Predator↔Recon (XC)',
  };
  return labels[channelName] || `📡 ${channelName}`;
}

function getAvatarColor(from) {
  const colors = {
    'Recon': '#6366f1',
    'recon': '#6366f1',
    'Recon (broadcast)': '#6366f1',
    'default': '#f59e0b',
    'predator': '#ef4444',
    'Predator': '#ef4444',
  };
  return colors[from] || '#10b981';
}

// Read all channel files
const channelFiles = fs.readdirSync(MESSAGES_DIR).filter(f => f.endsWith('.jsonl'));
const channels = [];

for (const file of channelFiles) {
  const channelName = file.replace('.jsonl', '');
  const messages = readJsonl(path.join(MESSAGES_DIR, file));
  if (messages.length > 0) {
    channels.push({ name: channelName, messages });
  }
}

// Sort channels by latest message timestamp
channels.sort((a, b) => {
  const aLast = a.messages[a.messages.length - 1]?.ts || 0;
  const bLast = b.messages[b.messages.length - 1]?.ts || 0;
  return bLast - aLast;
});

const totalMessages = channels.reduce((s, c) => s + c.messages.length, 0);
const generatedAt = new Date().toISOString();

// Build HTML
const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Recon — Walkie Dashboard</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: #0f1117;
    color: #e2e8f0;
    min-height: 100vh;
  }
  .header {
    background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
    padding: 20px 24px;
    border-bottom: 1px solid #3730a3;
  }
  .header h1 {
    font-size: 20px;
    font-weight: 700;
    color: #fff;
  }
  .header .meta {
    font-size: 12px;
    color: #a5b4fc;
    margin-top: 4px;
  }
  .stats {
    display: flex;
    gap: 16px;
    margin-top: 12px;
  }
  .stat {
    background: rgba(255,255,255,0.08);
    padding: 6px 12px;
    border-radius: 8px;
    font-size: 13px;
  }
  .stat span { color: #a5b4fc; font-weight: 600; }
  .layout {
    display: flex;
    height: calc(100vh - 100px);
  }
  .sidebar {
    width: 240px;
    min-width: 240px;
    background: #1a1b26;
    border-right: 1px solid #2a2b3d;
    overflow-y: auto;
  }
  .sidebar-title {
    padding: 12px 16px 8px;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: #64748b;
  }
  .channel-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    width: 100%;
    padding: 10px 16px;
    background: none;
    border: none;
    color: #94a3b8;
    cursor: pointer;
    text-align: left;
    font-size: 13px;
    transition: all 0.15s;
  }
  .channel-btn:hover { background: #25263a; color: #e2e8f0; }
  .channel-btn.active { background: #312e81; color: #fff; border-left: 3px solid #818cf8; }
  .channel-btn .count {
    margin-left: auto;
    background: #334155;
    padding: 2px 8px;
    border-radius: 10px;
    font-size: 11px;
  }
  .channel-btn.active .count { background: #4f46e5; }
  .main {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }
  .channel-header {
    padding: 14px 20px;
    background: #1a1b26;
    border-bottom: 1px solid #2a2b3d;
    font-size: 15px;
    font-weight: 600;
  }
  .messages {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
  }
  .msg {
    margin-bottom: 16px;
    display: flex;
    gap: 10px;
  }
  .avatar {
    width: 34px;
    height: 34px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 13px;
    font-weight: 700;
    color: #fff;
    flex-shrink: 0;
  }
  .msg-body { flex: 1; min-width: 0; }
  .msg-header {
    display: flex;
    align-items: baseline;
    gap: 8px;
    margin-bottom: 3px;
  }
  .msg-from { font-weight: 600; font-size: 13px; }
  .msg-time { font-size: 11px; color: #64748b; }
  .msg-text {
    font-size: 13.5px;
    line-height: 1.55;
    color: #cbd5e1;
    word-wrap: break-word;
  }
  .msg-text code {
    background: #1e293b;
    padding: 1px 5px;
    border-radius: 4px;
    font-size: 12.5px;
    color: #fbbf24;
  }
  .msg-text strong { color: #e2e8f0; }
  .system-msg {
    text-align: center;
    color: #475569;
    font-size: 12px;
    padding: 8px;
    font-style: italic;
  }
  .no-messages {
    text-align: center;
    color: #475569;
    padding: 40px 20px;
    font-size: 14px;
  }
  .refresh-bar {
    padding: 8px 20px;
    background: #1a1b26;
    border-top: 1px solid #2a2b3d;
    font-size: 11px;
    color: #64748b;
    display: flex;
    justify-content: space-between;
  }
  .refresh-bar button {
    background: #4f46e5;
    color: #fff;
    border: none;
    padding: 4px 12px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 11px;
  }
  .refresh-bar button:hover { background: #4338ca; }
</style>
</head>
<body>
<div class="header">
  <h1>📡 Recon Walkie Dashboard</h1>
  <div class="meta">Agent-to-Agent Conversation Monitor · Auto-refreshes every 5 minutes</div>
  <div class="stats">
    <div class="stat">Channels: <span>${channels.length}</span></div>
    <div class="stat">Messages: <span>${totalMessages}</span></div>
    <div class="stat">Updated: <span>${generatedAt.slice(0, 19)} UTC</span></div>
  </div>
</div>
<div class="layout">
  <div class="sidebar">
    <div class="sidebar-title">Channels</div>
    ${channels.map((ch, i) => `
    <button class="channel-btn ${i === 0 ? 'active' : ''}" onclick="showChannel('${ch.name}', this)">
      ${getChannelLabel(ch.name)}
      <span class="count">${ch.messages.length}</span>
    </button>`).join('')}
  </div>
  <div class="main">
    ${channels.map((ch, i) => `
    <div class="channel-view" id="view-${ch.name}" style="display:${i === 0 ? 'flex' : 'none'};flex-direction:column;height:100%;">
      <div class="channel-header">${getChannelLabel(ch.name)}</div>
      <div class="messages">
        ${ch.messages.map(m => {
          const isSystem = m.data && m.data.startsWith('[system]');
          if (isSystem) {
            return `<div class="system-msg">${escapeHtml(m.data)}</div>`;
          }
          const initial = (m.from || '?')[0].toUpperCase();
          const color = getAvatarColor(m.from);
          return `
        <div class="msg">
          <div class="avatar" style="background:${color}">${initial}</div>
          <div class="msg-body">
            <div class="msg-header">
              <span class="msg-from" style="color:${color}">${escapeHtml(m.from || 'unknown')}</span>
              <span class="msg-time">${formatTime(m.ts)}</span>
            </div>
            <div class="msg-text">${formatMessageText(m.data || '')}</div>
          </div>
        </div>`;
        }).join('')}
      </div>
    </div>`).join('')}
  </div>
</div>
<div class="refresh-bar">
  <span>Last generated: ${generatedAt}</span>
  <button onclick="location.reload()">↻ Refresh</button>
</div>
<script>
function showChannel(name, btn) {
  document.querySelectorAll('.channel-view').forEach(v => v.style.display = 'none');
  document.querySelectorAll('.channel-btn').forEach(b => b.classList.remove('active'));
  const view = document.getElementById('view-' + name);
  if (view) { view.style.display = 'flex'; view.querySelector('.messages').scrollTop = view.querySelector('.messages').scrollHeight; }
  if (btn) btn.classList.add('active');
}
// Auto-scroll to bottom of active channel
document.addEventListener('DOMContentLoaded', () => {
  const active = document.querySelector('.channel-view[style*="display: flex"]');
  if (active) { const msgs = active.querySelector('.messages'); msgs.scrollTop = msgs.scrollHeight; }
});
</script>
</body>
</html>`;

fs.writeFileSync(OUTPUT, html);
// Also write as index.html for root access
const indexPath = path.join(__dirname, '..', 'dashboard', 'index.html');
fs.writeFileSync(indexPath, html);
console.log(`Dashboard generated: ${OUTPUT} (${channels.length} channels, ${totalMessages} messages)`);
