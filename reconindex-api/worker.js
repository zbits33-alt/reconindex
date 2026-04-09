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
      ],
    }, { ...cors }, 404);
  },
};

// ═══════════════════════════════════════════════════════
// CHAT ENDPOINTS
// ═══════════════════════════════════════════════════════

// GET /chat/resolve?code=XXX
async function handleChatResolve(request, env, cors) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  if (!code) return jsonResponse({ error: "code parameter required" }, { ...cors }, 400);

  // Look up source by api_token
  const sources = await supabaseSelect(env, "sources", `id,name,type,owner,active,created_at`, `api_token=eq.${code}`, 1);
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

function jsonResponse(data, headers, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...headers },
  });
}
