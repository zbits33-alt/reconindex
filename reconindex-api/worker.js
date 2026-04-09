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

    // Health check
    if (path === "/health" && method === "GET") {
      return jsonResponse({ status: "ok", timestamp: new Date().toISOString() }, cors);
    }

    // POST /intake/submit
    if (path === "/intake/submit" && method === "POST") {
      return handleIntakeSubmit(request, env, cors);
    }

    // POST /intake/register (admin only)
    if (path === "/intake/register" && method === "POST") {
      return handleIntakeRegister(request, env, cors);
    }

    // GET /intake/status/:id
    if (path.startsWith("/intake/status/") && method === "GET") {
      const id = path.split("/").pop();
      return handleIntakeStatus(id, env, cors);
    }

    // POST /chat/send — Relay message to Recon via Walkie
    if (path === "/chat/send" && method === "POST") {
      return handleChatSend(request, env, cors);
    }

    // GET /chat/receive — Get Recon's latest responses
    if (path === "/chat/receive" && method === "GET") {
      return handleChatReceive(url, env, cors);
    }

    return jsonResponse({ error: "Not found" }, { ...cors }, 404);
  },
};

// ──────────────────────────────────────────────
// POST /intake/submit
// ──────────────────────────────────────────────
async function handleIntakeSubmit(request, env, cors) {
  const auth = request.headers.get("Authorization");
  if (!auth || !auth.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing bearer token" }, { ...cors }, 401);
  }

  const token = auth.slice(7);

  // Verify token against sources table
  const source = await supabaseQuery(env, "SELECT id, active FROM sources WHERE api_token = $1 LIMIT 1", [token]);
  if (source.length === 0) {
    return jsonResponse({ error: "Invalid token" }, { ...cors }, 401);
  }
  if (!source[0].active) {
    return jsonResponse({ error: "Source is inactive" }, { ...cors }, 403);
  }

  const sourceId = source[0].id;

  // Parse and validate payload
  let body;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, { ...cors }, 400);
  }

  const required = ["category", "summary", "content"];
  for (const field of required) {
    if (!body[field]) {
      return jsonResponse({ error: `Missing field: ${field}` }, { ...cors }, 400);
    }
  }

  const validCategories = [
    "identity", "build", "operational", "performance",
    "failure", "knowledge", "safety", "friction", "audit_request"
  ];
  if (!validCategories.includes(body.category)) {
    return jsonResponse({ error: `Invalid category. Must be one of: ${validCategories.join(", ")}` }, { ...cors }, 400);
  }

  // Insert submission
  const result = await supabaseQuery(
    env,
    `INSERT INTO submissions (source_id, tier, category, summary, content, status, meta)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING id, submitted_at, status`,
    [
      sourceId,
      body.tier || 2,
      body.category,
      body.summary,
      body.content,
      "received",
      JSON.stringify(body.meta || {}),
    ]
  );

  const submissionId = result[0].id;

  return jsonResponse({
    success: true,
    submission_id: submissionId,
    status: "received",
    message: "Submission received and queued for classification",
  }, cors);
}

// ──────────────────────────────────────────────
// POST /intake/register (admin)
// ──────────────────────────────────────────────
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

  // Insert source
  const source = await supabaseQuery(
    env,
    `INSERT INTO sources (name, type, owner, ecosystem, api_token)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, name, api_token`,
    [body.name, body.type, body.owner || null, body.ecosystem || [], body.api_token]
  );

  // Insert default permissions
  await supabaseQuery(
    env,
    `INSERT INTO permissions (source_id, default_tier)
     VALUES ($1, $2)`,
    [source[0].id, body.default_tier || 2]
  );

  return jsonResponse({
    success: true,
    source: {
      id: source[0].id,
      name: source[0].name,
    },
    message: "Source registered successfully",
  }, cors);
}

// ──────────────────────────────────────────────
// GET /intake/status/:id
// ──────────────────────────────────────────────
async function handleIntakeStatus(id, env, cors) {
  const result = await supabaseQuery(
    env,
    `SELECT id, source_id, category, summary, status, usefulness_score, submitted_at
     FROM submissions WHERE id = $1 LIMIT 1`,
    [id]
  );

  if (result.length === 0) {
    return jsonResponse({ error: "Submission not found" }, { ...cors }, 404);
  }

  return jsonResponse({ submission: result[0] }, cors);
}

// ──────────────────────────────────────────────
// Supabase query helper
// ──────────────────────────────────────────────
async function supabaseQuery(env, sql, params) {
  const res = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "apikey": env.SUPABASE_SERVICE_KEY,
      "Authorization": `Bearer ${env.SUPABASE_SERVICE_KEY}`,
      "Prefer": "params=single-object",
    },
    body: JSON.stringify({ sql, params }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Supabase error ${res.status}: ${errText}`);
  }

  return res.json();
}

function jsonResponse(data, headers, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...headers },
  });
}
