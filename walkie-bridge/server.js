const http = require('http');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const PORT = 8787;
const WALKIE = process.env.HOME + '/.npm-global/bin/walkie';
const WORKSPACE = process.env.HOME + '/workspace';

// Known channels with their secrets
const CHANNELS = {
  'general': { secret: null, label: 'General' },
  'quantx-bridge': { secret: 'qx-9f3a-dom2025', label: 'QuantX Bridge' },
  'predator-collab': { secret: 'xpl-77fc0cdfdfdba14b', label: 'Predator Collab' },
};

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

function jsonResponse(res, data, status = 200) {
  res.writeHead(status, { 'Content-Type': 'application/json', ...cors });
  res.end(JSON.stringify(data));
}

// Parse walkie inbox file into messages
function parseInbox(filePath) {
  try {
    const raw = fs.readFileSync(filePath, 'utf-8');
    const lines = raw.split('\n');
    const messages = [];
    const msgPattern = /^\[([^\]]+)\]\s*\[([^\]]+)\]\s*(\w+):\s*(.*)/;

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed === 'No new messages') continue;
      const m = trimmed.match(msgPattern);
      if (m) {
        messages.push({
          ts: m[1],
          display: m[2],
          from: m[3],
          text: m[4],
          type: 'message'
        });
      }
    }
    return messages;
  } catch {
    return [];
  }
}

function sendWalkie(channel, text, from = 'Recon') {
  const ch = CHANNELS[channel];
  if (!ch) return { ok: false, error: 'Unknown channel' };

  let channelArg;
  if (ch.secret) {
    channelArg = `${channel}:${ch.secret}`;
  } else {
    channelArg = channel;
  }

  const escaped = text.replace(/"/g, '\\"').replace(/`/g, '\\`').replace(/\$/g, '\\$');
  const cmd = `WALKIE_ID="${from}" ${WALKIE} send "${channelArg}" "${escaped}"`;

  try {
    const result = execSync(cmd, { encoding: 'utf-8', timeout: 15000, env: { ...process.env, WALKIE_ID: from } });
    return { ok: true, output: result.trim() };
  } catch (e) {
    return { ok: false, error: e.message };
  }
}

function readWalkie(channel) {
  const ch = CHANNELS[channel];
  if (!ch) return { ok: false, error: 'Unknown channel' };

  let channelArg;
  if (ch.secret) {
    channelArg = `${channel}:${ch.secret}`;
  } else {
    channelArg = channel;
  }

  try {
    const result = execSync(
      `${WALKIE} read "${channelArg}"`,
      { encoding: 'utf-8', timeout: 5000 }
    );
    // Write to a channel-specific inbox for web polling
    const inboxPath = path.join(WORKSPACE, `walkie-${channel}-inbox.txt`);
    fs.writeFileSync(inboxPath, result);
    return { ok: true, messages: parseInbox(inboxPath) };
  } catch (e) {
    return { ok: false, error: e.message };
  }
}

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, cors);
    res.end();
    return;
  }

  const url = new URL(req.url, `http://localhost:${PORT}`);

  // GET /channels
  if (url.pathname === '/channels' && req.method === 'GET') {
    const list = Object.entries(CHANNELS).map(([id, ch]) => ({
      id, label: ch.label,
    }));
    return jsonResponse(res, { channels: list });
  }

  // GET /messages?channel=general
  if (url.pathname === '/messages' && req.method === 'GET') {
    const channel = url.searchParams.get('channel') || 'general';
    const inboxPath = path.join(WORKSPACE, `walkie-${channel}-inbox.txt`);
    const messages = parseInbox(inboxPath);
    return jsonResponse(res, { channel, messages });
  }

  // POST /refresh?channel=general — call walkie read to fetch new messages
  if (url.pathname === '/refresh' && req.method === 'POST') {
    const channel = url.searchParams.get('channel') || 'general';
    const result = readWalkie(channel);
    return jsonResponse(res, result);
  }

  // POST /send
  if (url.pathname === '/send' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const { channel, text, from } = JSON.parse(body);
        if (!channel || !text) {
          return jsonResponse(res, { ok: false, error: 'channel and text required' }, 400);
        }
        const result = sendWalkie(channel, text, from || 'Recon');
        return jsonResponse(res, result);
      } catch (e) {
        return jsonResponse(res, { ok: false, error: e.message }, 500);
      }
    });
    return;
  }

  // GET /health
  if (url.pathname === '/health' && req.method === 'GET') {
    return jsonResponse(res, { status: 'ok', timestamp: new Date().toISOString() });
  }

  jsonResponse(res, { error: 'not found' }, 404);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Walkie bridge listening on port ${PORT}`);
});
