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

    // GET /sources — list all sources (admin)
    if (path === "/sources" && method === "GET") {
      return handleListSources(request, env, cors);
    }

    return jsonResponse({ error: "Not found", routes: ["/health", "/intake/submit", "/intake/register", "/intake/status/:id", "/sources"] }, { ...cors }, 404);
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
  const source = await supabaseSelect(env, "sources", `id,active`, `api_token=eq.${token}`, 1);
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
  const result = await supabaseInsert(env, "submissions", {
    source_id: sourceId,
    tier: body.tier || 2,
    category: body.category,
    summary: body.summary,
    content: body.content,
    status: "received",
    meta: body.meta || {},
  });

  const submissionId = result[0]?.id || result[0]?.id;

  return jsonResponse({
    success: true,
    submission_id: result[0].id,
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
  const source = await supabaseInsert(env, "sources", {
    name: body.name,
    type: body.type,
    owner: body.owner || null,
    ecosystem: body.ecosystem || [],
    api_token: body.api_token,
    default_tier: body.default_tier || 2,
  });

  // Insert default permissions
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

// ──────────────────────────────────────────────
// GET /intake/status/:id
// ──────────────────────────────────────────────
async function handleIntakeStatus(id, env, cors) {
  const result = await supabaseSelect(env, "submissions",
    `id,source_id,category,summary,status,usefulness_score,submitted_at`,
    `id=eq.${id}`, 1);

  if (result.length === 0) {
    return jsonResponse({ error: "Submission not found" }, { ...cors }, 404);
  }

  return jsonResponse({ submission: result[0] }, cors);
}

// ──────────────────────────────────────────────
// GET /sources (admin)
// ──────────────────────────────────────────────
async function handleListSources(request, env, cors) {
  const auth = request.headers.get("Authorization");
  if (auth !== `Bearer ${env.ADMIN_TOKEN}`) {
    return jsonResponse({ error: "Admin token required" }, { ...cors }, 401);
  }

  const sources = await supabaseSelect(env, "sources", `id,name,type,owner,active,created_at`, ``, 100);
  return jsonResponse({ sources }, cors);
}

// ──────────────────────────────────────────────
// Supabase REST API helpers
// ──────────────────────────────────────────────
async function supabaseSelect(env, table, columns, filter, limit) {
  let url = `${env.SUPABASE_URL}/rest/v1/${table}?select=${columns}`;
  if (filter) url += `&${filter}`;
  if (limit) url += `&limit=${limit}`;

  const res = await fetch(url, {
    headers: {
      "apikey": env.SUPABASE_SERVICE_KEY,
      "Authorization": `Bearer ${env.SUPABASE_SERVICE_KEY}`,
      "Prefer": "return=representation",
    },
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Supabase select error ${res.status}: ${errText}`);
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
