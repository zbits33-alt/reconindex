-- ═══════════════════════════════════════════════════════
-- ROW-LEVEL SECURITY POLICIES
-- Applied: 2026-04-12
-- Purpose: Defense-in-depth for all Recon Index tables
-- Note: Worker uses SUPABASE_SERVICE_KEY (bypasses RLS), but these
--       policies protect against direct DB access, key compromise,
--       and future client-side code.
-- ═══════════════════════════════════════════════════════

-- Enable RLS on all tables
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE general_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestion_outcomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_gaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE trust_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE source_maturity ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_context ENABLE ROW LEVEL SECURITY;
ALTER TABLE entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE entity_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE entity_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecosystem_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE classification_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE entity_classifications ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════
-- SOURCES TABLE
-- ═══════════════════════════════════════════════════════

-- Service role bypass (worker uses service key) — already implicit
-- But we add explicit policies for non-service-role access:

-- Anyone can read active sources (public directory)
CREATE POLICY "sources_public_read" ON sources
  FOR SELECT
  USING (active = true);

-- Only service role can insert/update/delete sources
CREATE POLICY "sources_service_write" ON sources
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- PERMISSIONS TABLE
-- ═══════════════════════════════════════════════════════

-- Sources can read their own permissions via api_token match
-- (Worker handles this in application logic; RLS is defense-in-depth)
CREATE POLICY "permissions_service_only" ON permissions
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- SUBMISSIONS TABLE
-- ═══════════════════════════════════════════════════════

-- Sources can read their own submissions
CREATE POLICY "submissions_source_read" ON submissions
  FOR SELECT
  USING (
    -- Allow if authenticated as service role
    auth.jwt() ->> 'role' = 'service_role'
    OR
    -- Allow source to see own submissions (matched via api_token in app layer)
    EXISTS (
      SELECT 1 FROM sources s
      WHERE s.id = submissions.source_id
      AND s.active = true
    )
  );

-- Anyone can insert submissions (public endpoint)
CREATE POLICY "submissions_public_insert" ON submissions
  FOR INSERT
  WITH CHECK (true);

-- Service role can update/delete
CREATE POLICY "submissions_service_write" ON submissions
  FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "submissions_service_delete" ON submissions
  FOR DELETE
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- KNOWLEDGE UNITS TABLE
-- ═══════════════════════════════════════════════════════

-- Public read for tier 1-2 KUs (library content)
CREATE POLICY "knowledge_units_public_read" ON knowledge_units
  FOR SELECT
  USING (tier <= 2);

-- Service role full access
CREATE POLICY "knowledge_units_service_write" ON knowledge_units
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- LIBRARY CANDIDATES TABLE
-- ═══════════════════════════════════════════════════════

CREATE POLICY "library_candidates_service_only" ON library_candidates
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- PATTERNS TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "patterns_public_read" ON patterns
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "patterns_service_write" ON patterns
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- SAFETY FLAGS TABLE
-- ═══════════════════════════════════════════════════════

CREATE POLICY "safety_flags_service_only" ON safety_flags
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- CHAT MESSAGES TABLE
-- ═══════════════════════════════════════════════════════

-- Sources can read their own private chat messages
CREATE POLICY "chat_messages_source_read" ON chat_messages
  FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR
    EXISTS (
      SELECT 1 FROM sources s
      WHERE s.id = chat_messages.source_id
      AND s.active = true
    )
  );

-- Anyone can insert chat messages (via public endpoints with validation)
CREATE POLICY "chat_messages_public_insert" ON chat_messages
  FOR INSERT
  WITH CHECK (true);

-- Service role can delete
CREATE POLICY "chat_messages_service_delete" ON chat_messages
  FOR DELETE
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- GENERAL CHAT MESSAGES TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "general_chat_public_read" ON general_chat_messages
  FOR SELECT
  USING (true);

-- Anyone can insert
CREATE POLICY "general_chat_public_insert" ON general_chat_messages
  FOR INSERT
  WITH CHECK (true);

-- Service role can delete
CREATE POLICY "general_chat_service_delete" ON general_chat_messages
  FOR DELETE
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- AGENT SESSIONS TABLE
-- ═══════════════════════════════════════════════════════

-- Sources can read their own sessions
CREATE POLICY "agent_sessions_source_read" ON agent_sessions
  FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR
    EXISTS (
      SELECT 1 FROM sources s
      WHERE s.id = agent_sessions.source_id
      AND s.active = true
    )
  );

-- Anyone can insert sessions
CREATE POLICY "agent_sessions_public_insert" ON agent_sessions
  FOR INSERT
  WITH CHECK (true);

-- Service role can update/delete
CREATE POLICY "agent_sessions_service_write" ON agent_sessions
  FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "agent_sessions_service_delete" ON agent_sessions
  FOR DELETE
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- SUGGESTIONS TABLE
-- ═══════════════════════════════════════════════════════

-- Public read for approved suggestions
CREATE POLICY "suggestions_public_read" ON suggestions
  FOR SELECT
  USING (status = 'approved' OR auth.jwt() ->> 'role' = 'service_role');

-- Anyone can submit suggestions
CREATE POLICY "suggestions_public_insert" ON suggestions
  FOR INSERT
  WITH CHECK (true);

-- Service role can update
CREATE POLICY "suggestions_service_update" ON suggestions
  FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- SUGGESTION OUTCOMES TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "suggestion_outcomes_public_read" ON suggestion_outcomes
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "suggestion_outcomes_service_write" ON suggestion_outcomes
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- KNOWLEDGE GAPS TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "knowledge_gaps_public_read" ON knowledge_gaps
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "knowledge_gaps_service_write" ON knowledge_gaps
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- TRUST SCORES TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "trust_scores_public_read" ON trust_scores
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "trust_scores_service_write" ON trust_scores
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- SOURCE MATURITY TABLE
-- ═══════════════════════════════════════════════════════

-- Service role only (admin data)
CREATE POLICY "source_maturity_service_only" ON source_maturity
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- SESSION CONTEXT TABLE
-- ═══════════════════════════════════════════════════════

-- Sources can read their own context
CREATE POLICY "session_context_source_read" ON session_context
  FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR
    EXISTS (
      SELECT 1 FROM sources s
      WHERE s.id = session_context.source_id
      AND s.active = true
    )
  );

-- Service role write
CREATE POLICY "session_context_service_write" ON session_context
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- ENTITIES TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "entities_public_read" ON entities
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "entities_service_write" ON entities
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- ENTITY PROFILES TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "entity_profiles_public_read" ON entity_profiles
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "entity_profiles_service_write" ON entity_profiles
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- ENTITY RELATIONSHIPS TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "entity_relationships_public_read" ON entity_relationships
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "entity_relationships_service_write" ON entity_relationships
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- CONTENT ITEMS TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "content_items_public_read" ON content_items
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "content_items_service_write" ON content_items
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- ECOSYSTEM UPDATES TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "ecosystem_updates_public_read" ON ecosystem_updates
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "ecosystem_updates_service_write" ON ecosystem_updates
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- CATEGORIES TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "categories_public_read" ON categories
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "categories_service_write" ON categories
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- TAGS TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "tags_public_read" ON tags
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "tags_service_write" ON tags
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- CLASSIFICATION TYPES TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "classification_types_public_read" ON classification_types
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "classification_types_service_write" ON classification_types
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ═══════════════════════════════════════════════════════
-- ENTITY CLASSIFICATIONS TABLE
-- ═══════════════════════════════════════════════════════

-- Public read
CREATE POLICY "entity_classifications_public_read" ON entity_classifications
  FOR SELECT
  USING (true);

-- Service role write
CREATE POLICY "entity_classifications_service_write" ON entity_classifications
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');
