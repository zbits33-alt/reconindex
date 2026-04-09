export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS headers
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };

    if (method === "OPTIONS") {
      return new Response(null, { headers: cors });
    }

    // ─── Health ───
    if (path === "/health" && method === "GET") {
      return jsonResponse({ status: "ok", timestamp: new Date().toISOString() }, cors);
    }

    // ─── Intake endpoints ───
    if (path === "/intake/submit" && method === "POST") {
      return handleIntakeSubmit(request, env, cors);
    }
    if (path === "/intake/register" && method === "POST") {
      return handleIntakeRegister(request, env, cors);
    }
    if (path.startsWith("/intake/status/") && method === "GET") {
      const id = path.split("/").pop();
      return handleIntakeStatus(id, env, cors);
    }
    if (path === "/sources" && method === "GET") {
      return handleListSources(request, env, cors);
    }

    // ─── Chat endpoints ───
    // GET /chat/resolve?code=XXXX → resolve agent code to agent data
    if (path === "/chat/resolve" && method === "GET") {
      return handleChatResolve(request, env, cors);
    }

    // GET /chat/messages?source_id=X&room=private|general → get messages
    if (path === "/chat/messages" && method === "GET") {
      return handleChatMessages(request, env, cors);
    }

    // POST /chat/message → send a message
    if (path === "/chat/message" && method === "POST") {
      return handleChatMessage(request, env, cors);
    }

    // GET /chat/sessions?source_id=X → get session history
    if (path === "/chat/sessions" && method === "GET") {
      return handleChatSessions(request, env, cors);
    }

    // GET /chat/owner → owner view: all agents + stats (admin auth)
    if (path === "/chat/owner" && method === "GET") {
      return handleChatOwner(request, env, cors);
    }

    // GET /chat/agents → list all connected agents (public, no secrets)
    if (path === "/chat/agents" && method === "GET") {
      return handleChatAgentsList(request, env, cors);
    }

    // ─── Suggestion Box endpoints ───
    // POST /suggestions/submit
    if (path === "/suggestions/submit" && method === "POST") {
      return handleSuggestionSubmit(request, env, cors);
    }

    // GET /suggestions?status=X&category=Y
    if (path === "/suggestions" && method === "GET") {
      return handleSuggestionsList(request, env, cors);
    }

    // GET /suggestions/stats
    if (path === "/suggestions/stats" && method === "GET") {
      return handleSuggestionsStats(request, env, cors);
    }

    // GET /status — live stats from Supabase (no auth)
    if (path === "/status" && method === "GET") {
      return handleStatus(request, env, cors);
    }

    // GET /libraries — collection entries from local index (no auth)
    if (path === "/libraries" && method === "GET") {
      return handleLibraries(request, env, cors);
    }

    return jsonResponse({
      error: "Not found",
      routes: [
        "/health",
        "/intake/submit",
        "/intake/register",
        "/intake/status/:id",
        "/sources",
        "/chat/resolve",
        "/chat/messages",
        "/chat/message",
        "/chat/sessions",
        "/chat/owner",
        "/chat/agents",
        "/suggestions/submit",
        "/suggestions",
        "/suggestions/stats",
      ],
    }, { ...cors }, 404);
  },
};

// ═══════════════════════════════════════════════════════
// CHAT ENDPOINTS
// ═══════════════════════════════════════════════════════

// Simple login codes — map human-friendly codes to agent source IDs
const LOGIN_CODES = {
  "PRED-7777": "f1bdb866-b438-46c9-8d1d-48c64a309425",    // Predator
  "RECON-0001": "12cd9959-9fcc-47ca-b0dc-54e7e972f8e9", // Recon
  "DKT-0003": "0d010998-8981-4b89-83e5-283356888b02",   // DKTrenchBot
};

// GET /chat/resolve?code=XXX
async function handleChatResolve(request, env, cors) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  if (!code) return jsonResponse({ error: "code parameter required" }, { ...cors }, 400);

  let sourceId = null;

  // Try simple login code first
  const cleanCode = code.replace(/-/g, "").toUpperCase();
  for (const [loginCode, srcId] of Object.entries(LOGIN_CODES)) {
    if (loginCode.replace(/-/g, "") === cleanCode) {
      sourceId = srcId;
      break;
    }
  }

  // If no login code match, try as raw api_token
  if (!sourceId) {
    const sources = await supabaseSelect(env, "sources", `id,active`, `api_token=eq.${code}`, 1);
    if (sources.length > 0) sourceId = sources[0].id;
  }

  if (!sourceId) return jsonResponse({ agent: null }, cors);

  // Look up source details
  const sources = await supabaseSelect(env, "sources", `id,name,type,owner,active,created_at`, `id=eq.${sourceId}`, 1);
  if (sources.length === 0) return jsonResponse({ agent: null }, cors);

  const source = sources[0];
  if (!source.active) return jsonResponse({ error: "Source is inactive" }, { ...cors }, 403);

  // Get submission count
  const subs = await supabaseSelect(env, "submissions", `count`, `source_id=eq.${source.id}`, 1);

  // Create session
  await supabaseInsert(env, "agent_sessions", {
    source_id: source.id,
    started_at: new Date().toISOString(),
  });

  return jsonResponse({
    agent: {
      source_id: source.id,
      name: source.name,
      type: source.type,
      owner: source.owner,
      online: true,
      first_seen: source.created_at,
      submission_count: subs[0]?.count || 0,
    },
  }, cors);
}

// GET /chat/messages?source_id=X&room=private|general&after_id=Y
async function handleChatMessages(request, env, cors) {
  const url = new URL(request.url);
  const sourceId = url.searchParams.get("source_id");
  const room = url.searchParams.get("room") || "private";
  const afterId = url.searchParams.get("after_id");

  if (!sourceId && room !== "general") {
    return jsonResponse({ error: "source_id required for private rooms" }, { ...cors }, 400);
  }

  let query = "";
  if (room === "general") {
    query = "id, sender, sender_id, message, created_at";
  } else {
    query = "id, sender, message, created_at";
  }

  let filter = room === "general" ? "" : `source_id=eq.${sourceId}`;
  let order = "created_at.desc";

  if (afterId) {
    // Only get new messages
    const newMsgs = await supabaseSelect(
      env,
      room === "general" ? "general_chat_messages" : "chat_messages",
      query,
      `id=gt.${afterId}`,
      100
    );
    return jsonResponse({ messages: newMsgs, room }, cors);
  }

  const msgs = await supabaseSelect(
    env,
    room === "general" ? "general_chat_messages" : "chat_messages",
    query,
    filter,
    200
  );

  return jsonResponse({ messages: msgs, room }, cors);
}

// POST /chat/message
async function handleChatMessage(request, env, cors) {
  const auth = request.headers.get("Authorization");
  if (!auth || !auth.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing bearer token" }, { ...cors }, 401);
  }
  const token = auth.slice(7);

  // Verify source
  const sources = await supabaseSelect(env, "sources", `id,name,type,active`, `api_token=eq.${token}`, 1);
  if (sources.length === 0) return jsonResponse({ error: "Invalid token" }, { ...cors }, 401);
  if (!sources[0].active) return jsonResponse({ error: "Source inactive" }, { ...cors }, 403);

  const source = sources[0];

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, { ...cors }, 400);
  }

  if (!body.message || !body.message.trim()) {
    return jsonResponse({ error: "message is required" }, { ...cors }, 400);
  }

  const room = body.room || "private";
  const maxLen = 2000;

  if (room === "general") {
    // Send to general chat
    const result = await supabaseInsert(env, "general_chat_messages", {
      sender: source.name,
      sender_id: source.id,
      message: body.message.trim().slice(0, maxLen),
    });
    return jsonResponse({ success: true, message_id: result[0]?.id, room: "general" }, cors);
  } else {
    // Send to private chat
    const result = await supabaseInsert(env, "chat_messages", {
      source_id: source.id,
      sender: "agent",
      message: body.message.trim().slice(0, maxLen),
    });
    return jsonResponse({ success: true, message_id: result[0]?.id, room: "private" }, cors);
  }
}

// GET /chat/sessions?source_id=X
async function handleChatSessions(request, env, cors) {
  const url = new URL(request.url);
  const sourceId = url.searchParams.get("source_id");
  if (!sourceId) return jsonResponse({ error: "source_id required" }, { ...cors }, 400);

  const sessions = await supabaseSelect(
    env,
    "agent_sessions",
    `id,source_id,started_at,ended_at,meta`,
    `source_id=eq.${sourceId}`,
    100
  );

  return jsonResponse({ sessions }, cors);
}

// GET /chat/owner (admin only)
async function handleChatOwner(request, env, cors) {
  const auth = request.headers.get("Authorization");
  if (auth !== `Bearer ${env.ADMIN_TOKEN}`) {
    return jsonResponse({ error: "Admin token required" }, { ...cors }, 401);
  }

  // Get all sources (without api_token)
  const sources = await supabaseSelect(env, "sources", `id,name,type,owner,active,created_at,meta`, ``, 100);

  // Get total message counts
  const generalMsgs = await supabaseSelect(env, "general_chat_messages", `count`, ``, 1);

  // Build agent list with message counts
  const agents = [];
  for (const s of sources) {
    const privMsgs = await supabaseSelect(env, "chat_messages", `count`, `source_id=eq.${s.id}`, 1);
    const sessCount = await supabaseSelect(env, "agent_sessions", `count`, `source_id=eq.${s.id}`, 1);
    agents.push({
      source_id: s.id,
      name: s.name,
      type: s.type,
      owner: s.owner,
      active: s.active,
      created_at: s.created_at,
      private_messages: privMsgs[0]?.count || 0,
      sessions: sessCount[0]?.count || 0,
    });
  }

  return jsonResponse({
    agents,
    total_general_messages: generalMsgs[0]?.count || 0,
    total_agents: agents.length,
  }, cors);
}

// GET /chat/agents (public list)
async function handleChatAgentsList(request, env, cors) {
  const sources = await supabaseSelect(
    env,
    "sources",
    `id,name,type,owner,active,created_at`,
    `active=eq.true`,
    100
  );

  // Get general chat message count
  const generalMsgs = await supabaseSelect(env, "general_chat_messages", `count`, ``, 1);

  return jsonResponse({
    agents: sources.map(s => ({
      source_id: s.id,
      name: s.name,
      type: s.type,
    })),
    general_message_count: generalMsgs[0]?.count || 0,
  }, cors);
}

// ═══════════════════════════════════════════════════════
// INTAKE ENDPOINTS (existing)
// ═══════════════════════════════════════════════════════

async function handleIntakeSubmit(request, env, cors) {
  const auth = request.headers.get("Authorization");
  if (!auth || !auth.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing bearer token" }, { ...cors }, 401);
  }

  const token = auth.slice(7);
  const source = await supabaseSelect(env, "sources", `id,active`, `api_token=eq.${token}`, 1);
  if (source.length === 0) return jsonResponse({ error: "Invalid token" }, { ...cors }, 401);
  if (!source[0].active) return jsonResponse({ error: "Source is inactive" }, { ...cors }, 403);

  const sourceId = source[0].id;

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, { ...cors }, 400);
  }

  const required = ["category", "summary", "content"];
  for (const field of required) {
    if (!body[field]) return jsonResponse({ error: `Missing field: ${field}` }, { ...cors }, 400);
  }

  const validCategories = [
    "identity", "build", "operational", "performance",
    "failure", "knowledge", "safety", "friction", "audit_request"
  ];
  if (!validCategories.includes(body.category)) {
    return jsonResponse({ error: `Invalid category. Must be one of: ${validCategories.join(", ")}` }, { ...cors }, 400);
  }

  const result = await supabaseInsert(env, "submissions", {
    source_id: sourceId,
    tier: body.tier || 2,
    category: body.category,
    summary: body.summary,
    content: body.content,
    status: "received",
    meta: body.meta || {},
  });

  return jsonResponse({
    success: true,
    submission_id: result[0].id,
    status: "received",
    message: "Submission received and queued for classification",
  }, cors);
}

async function handleIntakeRegister(request, env, cors) {
  const auth = request.headers.get("Authorization");
  if (auth !== `Bearer ${env.ADMIN_TOKEN}`) {
    return jsonResponse({ error: "Admin token required" }, { ...cors }, 401);
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, { ...cors }, 400);
  }

  if (!body.name || !body.type || !body.api_token) {
    return jsonResponse({ error: "name, type, and api_token are required" }, { ...cors }, 400);
  }

  const source = await supabaseInsert(env, "sources", {
    name: body.name,
    type: body.type,
    owner: body.owner || null,
    ecosystem: body.ecosystem || [],
    api_token: body.api_token,
  });

  await supabaseInsert(env, "permissions", {
    source_id: source[0].id,
    default_tier: body.default_tier || 2,
  });

  return jsonResponse({
    success: true,
    source: {
      id: source[0].id,
      name: source[0].name,
    },
    message: "Source registered successfully",
  }, cors);
}

async function handleIntakeStatus(id, env, cors) {
  const result = await supabaseSelect(env, "submissions",
    `id,source_id,category,summary,status,usefulness_score,submitted_at`,
    `id=eq.${id}`, 1);

  if (result.length === 0) return jsonResponse({ error: "Submission not found" }, { ...cors }, 404);
  return jsonResponse({ submission: result[0] }, cors);
}

async function handleListSources(request, env, cors) {
  const auth = request.headers.get("Authorization");
  if (auth !== `Bearer ${env.ADMIN_TOKEN}`) {
    return jsonResponse({ error: "Admin token required" }, { ...cors }, 401);
  }

  const sources = await supabaseSelect(env, "sources", `id,name,type,owner,active,created_at`, ``, 100);
  return jsonResponse({ sources }, cors);
}

// ═══════════════════════════════════════════════════════
// SUPABASE HELPERS
// ═══════════════════════════════════════════════════════

async function supabaseSelect(env, table, columns, filter, limit) {
  let url = `${env.SUPABASE_URL}/rest/v1/${table}?select=${columns}`;
  if (filter) url += `&${filter}`;
  if (limit) url += `&limit=${limit}`;

  // For count queries, use HEAD with count
  if (columns === "count") {
    url = `${env.SUPABASE_URL}/rest/v1/${table}`;
    if (filter) url += `&${filter}`;

    const res = await fetch(url, {
      method: "HEAD",
      headers: {
        "apikey": env.SUPABASE_SERVICE_KEY,
        "Authorization": `Bearer ${env.SUPABASE_SERVICE_KEY}`,
        "Prefer": "count=exact",
      },
    });

    const count = parseInt(res.headers.get("content-range")?.split("/")[1] || "0");
    return [{ count }];
  }

  const res = await fetch(url, {
    headers: {
      "apikey": env.SUPABASE_SERVICE_KEY,
      "Authorization": `Bearer ${env.SUPABASE_SERVICE_KEY}`,
      "Prefer": "return=representation",
    },
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error(`Supabase select error ${res.status}: ${errText}`);
    return [];
  }

  return res.json();
}

async function supabaseCount(env, table) {
  const url = `${env.SUPABASE_URL}/rest/v1/${table}?select=id`;
  const res = await fetch(url, {
    method: "HEAD",
    headers: {
      "apikey": env.SUPABASE_SERVICE_KEY,
      "Authorization": `Bearer ${env.SUPABASE_SERVICE_KEY}`,
      "Prefer": "count=exact",
    },
  });
  return parseInt(res.headers.get("content-range")?.split("/")[1] || "0");
}

async function supabaseInsert(env, table, data) {
  const res = await fetch(`${env.SUPABASE_URL}/rest/v1/${table}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "apikey": env.SUPABASE_SERVICE_KEY,
      "Authorization": `Bearer ${env.SUPABASE_SERVICE_KEY}`,
      "Prefer": "return=representation",
    },
    body: JSON.stringify(data),
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error(`Supabase insert error ${res.status}: ${errText}`);
    throw new Error(`Supabase insert error ${res.status}: ${errText}`);
  }

  return res.json();
}

// ═══════════════════════════════════════════════════════
// SUGGESTION BOX ENDPOINTS
// ═══════════════════════════════════════════════════════

async function handleSuggestionSubmit(request, env, cors) {
  let body;
  try { body = await request.json(); } catch {
    return jsonResponse({ error: "Invalid JSON" }, { ...cors }, 400);
  }

  const required = ["title", "description", "category"];
  for (const field of required) {
    if (!body[field]) return jsonResponse({ error: `${field} is required` }, { ...cors }, 400);
  }

  const validCategories = ["feature", "improvement", "bug", "integration", "documentation", "ecosystem", "other"];
  if (!validCategories.includes(body.category)) {
    return jsonResponse({ error: `Invalid category. Must be one of: ${validCategories.join(", ")}` }, { ...cors }, 400);
  }

  const validTypes = ["human", "agent", "bot", "tool"];
  const subType = validTypes.includes(body.submitter_type) ? body.submitter_type : "human";

  const validPriorities = ["low", "medium", "high", "critical"];
  const priority = validPriorities.includes(body.priority) ? body.priority : "medium";

  const result = await supabaseInsert(env, "suggestions", {
    submitter_name: (body.submitter_name || "Anonymous").slice(0, 100),
    submitter_type: subType,
    submitter_id: body.submitter_id || null,
    email: body.email || null,
    category: body.category,
    priority: priority,
    title: body.title.slice(0, 200),
    description: body.description.slice(0, 5000),
    status: "submitted",
  });

  return jsonResponse({
    success: true,
    suggestion_id: result[0]?.id,
    message: "Suggestion submitted. Recon will review it.",
  }, cors);
}

async function handleSuggestionsList(request, env, cors) {
  const url = new URL(request.url);
  const statuses = url.searchParams.getAll("status");
  const category = url.searchParams.get("category");
  const limit = Math.min(parseInt(url.searchParams.get("limit") || "50"), 100);

  let filter = "";
  if (statuses.length > 0) {
    filter = statuses.map(s => `status=eq.${s}`).join(" or ");
  }
  if (category) {
    filter += (filter ? " and " : "") + `category=eq.${category}`;
  }

  // Order by created_at desc
  filter += (filter ? "&" : "") + `order=created_at.desc&limit=${limit}`;

  const suggestions = await supabaseSelect(env, "suggestions",
    "id,submitter_name,submitter_type,category,priority,title,description,status,recon_notes,created_at,updated_at",
    filter, null);

  return jsonResponse({ suggestions }, cors);
}

async function handleSuggestionsStats(request, env, cors) {
  // Get counts by status
  const allSuggestions = await supabaseSelect(env, "suggestions", "id,status,category", "", 1000);

  const byStatus = {};
  const byCategory = {};
  let total = 0;

  for (const s of allSuggestions) {
    total++;
    byStatus[s.status] = (byStatus[s.status] || 0) + 1;
    byCategory[s.category] = (byCategory[s.category] || 0) + 1;
  }

  return jsonResponse({
    total,
    by_status: byStatus,
    by_category: byCategory,
  }, cors);
}

// ═══════════════════════════════════════════════════════
// STATUS ENDPOINT — live stats from Supabase
// ═══════════════════════════════════════════════════════

async function handleStatus(request, env, cors) {
  const [sources, generalMsgs, chatMsgs, sessions, submissions, knowledgeUnits, patterns, safetyFlags, suggestions] = await Promise.all([
    supabaseSelect(env, "sources", "id,name,type,owner,active,ecosystem,created_at", "", 100),
    supabaseCount(env, "general_chat_messages"),
    supabaseCount(env, "chat_messages"),
    supabaseCount(env, "agent_sessions"),
    supabaseCount(env, "submissions"),
    supabaseCount(env, "knowledge_units"),
    supabaseSelect(env, "patterns", "id,pattern_type,title,description,occurrence_count,first_seen,last_seen,tags", "", 50),
    supabaseSelect(env, "safety_flags", "id,flag_type,severity,description,resolved,created_at", "resolved=eq.false", 20),
    supabaseCount(env, "suggestions"),
  ]);

  // Get recent general chat messages (last 20)
  const recentMsgs = await supabaseSelect(env, "general_chat_messages", "id,sender,sender_id,message,created_at", "", 20);

  // Get recent submissions (last 10)
  const recentSubs = await supabaseSelect(env, "submissions", "id,source_id,category,summary,status,submitted_at", "", 10);

  // Count active sources
  const activeSources = sources.filter(s => s.active).length;

  return jsonResponse({
    timestamp: new Date().toISOString(),
    services: {
      api: true,
      supabase: true,
    },
    stats: {
      agents: sources.length,
      active_agents: activeSources,
      general_messages: generalMsgs,
      private_messages: chatMsgs,
      sessions: sessions,
      submissions: submissions,
      knowledge_units: knowledgeUnits,
      patterns: patterns.length,
      safety_flags: safetyFlags.filter(f => !f.resolved).length,
      suggestions: suggestions,
    },
    agents: sources.map(s => ({
      id: s.id,
      name: s.name,
      type: s.type,
      owner: s.owner,
      active: s.active,
      ecosystem: s.ecosystem || [],
      registered: s.created_at,
    })),
    recent_messages: recentMsgs,
    recent_submissions: recentSubs,
    patterns: (patterns || []).map(p => ({
      id: p.id,
      type: p.pattern_type,
      title: p.title,
      description: p.description,
      occurrences: p.occurrence_count,
      last_seen: p.last_seen,
      tags: p.tags || [],
    })),
    active_issues: safetyFlags.filter(f => !f.resolved).map(f => ({
      type: f.flag_type,
      severity: f.severity,
      description: f.description,
      created: f.created_at,
    })),
  }, cors);
}

// ═══════════════════════════════════════════════════════
// LIBRARIES ENDPOINT — collection entries (embedded)
// ═══════════════════════════════════════════════════════

// Embedded collection index — updated on each deploy
const COLLECTIONS = {
  updated: "2026-04-09T21:15:00Z",
  total_entries: 46,
  total_patterns: 6,
  total_agents: 3,
  library_candidates: 45,
  categories: {
    platform: {
      count: 17,
      entries: [
        { id: "RECON-P-001", title: "What is XRPLClaw", usefulness: 9, priority: 9.0 },
        { id: "RECON-P-002", title: "XRPLClaw agent setup — step by step", usefulness: 9, priority: 9.0 },
        { id: "RECON-P-003", title: "Standard vs Expert mode", usefulness: 8, priority: 8.0 },
        { id: "RECON-P-004", title: "How XRPLClaw billing works", usefulness: 8, priority: 8.0 },
        { id: "RECON-P-005", title: "XRPLClaw channels — web, Telegram, noVNC", usefulness: 7, priority: 7.0 },
        { id: "RECON-P-008", title: "What the agent can build — use case catalog", usefulness: 8, priority: 8.0 },
        { id: "RECON-P-010", title: "XRPLClaw cost optimization — 5 practices", usefulness: 9, priority: 9.0 },
      ]
    },
    guide: {
      count: 1,
      entries: [
        { id: "RECON-G-001", title: "Telegram setup for XRPLClaw agents", usefulness: 8, priority: 8.0 },
      ]
    },
    architecture: {
      count: 2,
      entries: [
        { id: "RECON-AR-001", title: "XRPLClaw architecture — plain language", usefulness: 7, priority: 7.0 },
        { id: "RECON-AR-002", title: "XRPLClaw agent memory — how it works", usefulness: 6, priority: 6.0 },
      ]
    },
    tools: {
      count: 14,
      entries: [
        { id: "RECON-T-001", title: "XRPL mainnet — what it is and how it works", usefulness: 9, priority: 9.0 },
        { id: "RECON-T-002", title: "XRPL accounts and reserves", usefulness: 9, priority: 9.0 },
        { id: "RECON-T-003", title: "XRPL trust lines", usefulness: 9, priority: 9.0 },
        { id: "RECON-T-004", title: "XRPL token issuance", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-005", title: "XRPL DEX — native orderbook", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-006", title: "XRPL AMMs", usefulness: 9, priority: 9.0 },
        { id: "RECON-T-007", title: "XRPL transaction types — capability map", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-008", title: "XRPL SDKs and API access", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-009", title: "XRPL EVM — what it is vs mainnet", usefulness: 9, priority: 9.0 },
        { id: "RECON-T-010", title: "XRPL EVM user setup", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-011", title: "XRPL EVM builder setup", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-012", title: "XRPL ↔ XRPL EVM bridge", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-013", title: "XRPL AMM — liquidity provision, LP tokens, and fees", usefulness: 9, priority: 9.0 },
        { id: "RECON-T-014", title: "XRPL DEX — market making strategies and spread management", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-015", title: "XRPL pathfinding — how it works and what builders must account for", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-016", title: "Price oracles on XRPL — what exists and current limitations", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-017", title: "XRPL Escrow — time-based and condition-based locking", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-018", title: "XRPL Payment Channels — streaming micropayments off-ledger", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-019", title: "XRPL NFTs — XLS-20 minting, offers, and royalties", usefulness: 8, priority: 8.0 },
        { id: "RECON-T-020", title: "XRPL Hooks — smart contract layer on Xahau", usefulness: 9, priority: 9.0 },
        { id: "RECON-T-021", title: "XRPL Multi-signing — threshold signatures for account security", usefulness: 9, priority: 9.0 },
      ]
    },
    safety: {
      count: 5,
      entries: [
        { id: "RECON-S-001", title: "Hot/warm/cold wallet architecture for XRPL token issuers", usefulness: 9, priority: 9.0 },
        { id: "RECON-S-002", title: "XRPL key management — master key, regular key, and disabling master", usefulness: 9, priority: 9.0 },
        { id: "RECON-S-003", title: "Common XRPL scam patterns — fake airdrops, trust line attacks, and social engineering", usefulness: 9, priority: 9.0 },
        { id: "RECON-S-004", title: "What never to store or share — seeds, private keys, and where secrets go wrong", usefulness: 10, priority: 10.0 },
        { id: "RECON-S-005", title: "SetRegularKey pattern for trading bots — hot key isolation", usefulness: 9, priority: 9.0 },
      ]
    },
    friction: {
      count: 5,
      entries: [
        { id: "RECON-X-001", title: "Telegram token conflict (409 error)", usefulness: 9, priority: 9.0 },
        { id: "RECON-X-002", title: "Balance floor — agent paused not offline", usefulness: 8, priority: 8.0 },
        { id: "RECON-X-003", title: "Background process lost on container restart", usefulness: 8, priority: 8.0 },
        { id: "RECON-X-004", title: "Xaman desktop payment — QR required", usefulness: 7, priority: 7.0 },
        { id: "RECON-X-005", title: "noVNC browser viewer undiscovered", usefulness: 7, priority: 7.0 },
      ]
    },
    failures: {
      count: 5,
      entries: [
        { id: "RECON-F-001", title: "AMM vs DEX slippage calculation mismatch — wrong formula applied", usefulness: 9, priority: 11.4 },
        { id: "RECON-F-002", title: "Reserve undercount causing tecINSUFFICIENT_RESERVE errors", usefulness: 9, priority: 11.4 },
        { id: "RECON-F-003", title: "Trust line not set before payment — tecNO_LINE or tecPATH_DRY failure", usefulness: 9, priority: 11.4 },
        { id: "RECON-F-004", title: "Bridge latency not handled in UX — users assume failed transactions", usefulness: 8, priority: 8.0 },
        { id: "RECON-F-005", title: "Rate limiting on public XRPL nodes causing bot failures", usefulness: 9, priority: 9.0 },
      ]
    },
  },
  patterns: [
    { id: "P-FRIC-001", type: "repeated_friction", title: "Users underestimate agent capabilities", occurrences: 4, status: "review_ready" },
    { id: "P-FRIC-002", type: "repeated_friction", title: "Billing misconceptions at onboarding", occurrences: 4, status: "review_ready" },
    { id: "P-FRIC-003", type: "repeated_friction", title: "Agent persistence ≠ process persistence", occurrences: 2, status: "watch" },
    { id: "P-FRIC-004", type: "repeated_friction", title: "XRPL mainnet vs EVM — wrong environment chosen", occurrences: 2, status: "watch" },
    { id: "P-FAIL-001", type: "repeated_failure", title: "XRPL reserve undercount — object count not tracked", occurrences: 3, status: "candidate" },
    { id: "P-SAFE-001", type: "repeated_safety_issue", title: "Key/seed exposure via unsafe storage or sharing", occurrences: 3, status: "candidate" },
  ],
};

async function handleLibraries(request, env, cors) {
  const url = new URL(request.url);
  const category = url.searchParams.get("category");
  const search = url.searchParams.get("search");

  let data = COLLECTIONS;

  // Filter by category if requested
  if (category && data.categories[category]) {
    data = {
      ...data,
      categories: { [category]: data.categories[category] },
    };
  }

  // Simple text search across all entry titles
  if (search) {
    const q = search.toLowerCase();
    const filtered = {};
    for (const [cat, catData] of Object.entries(data.categories || {})) {
      const matching = catData.entries.filter(e =>
        e.title.toLowerCase().includes(q) || e.id.toLowerCase().includes(q)
      );
      if (matching.length > 0) {
        filtered[cat] = { ...catData, entries: matching };
      }
    }
    data = { ...data, categories: filtered };
  }

  return jsonResponse(data, cors);
}

function jsonResponse(data, headers, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...headers },
  });
}
