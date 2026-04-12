-- RLS Defense-in-Depth Migration
-- Date: 2026-04-12
-- Purpose: Enable Row-Level Security on all tables
-- Note: Worker uses SUPABASE_SERVICE_KEY which bypasses RLS.
-- These policies protect against: direct Supabase access, key compromise, future client-side code.

-- ═══════════════════════════════════════════════════════
-- 1. Enable RLS on all tables
-- ═══════════════════════════════════════════════════════

ALTER TABLE public.sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suggestion_outcomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_trust_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ecosystem_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entity_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.general_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_gaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.source_maturity ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════
-- 2. Service role bypass (explicit, for documentation)
-- Service role key bypasses RLS automatically in Supabase.
-- These policies are for anon/authenticated access only.
-- ═══════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════
-- 3. Public read access — knowledge_units (tier 1 only)
-- Anonymous users can only see public (tier 1) knowledge units.
-- ═══════════════════════════════════════════════════════

CREATE POLICY "public_read_knowledge_units"
  ON public.knowledge_units
  FOR SELECT
  TO anon
  USING (tier = 1 AND status = 'published');

-- ═══════════════════════════════════════════════════════
-- 4. Public read access — patterns (published only)
-- ═══════════════════════════════════════════════════════

CREATE POLICY "public_read_patterns"
  ON public.patterns
  FOR SELECT
  TO anon
  USING (status = 'active');

-- ═══════════════════════════════════════════════════════
-- 5. Public read access — entities (published only)
-- ═══════════════════════════════════════════════════════

CREATE POLICY "public_read_entities"
  ON public.entities
  FOR SELECT
  TO anon
  USING (status = 'published');

-- ═══════════════════════════════════════════════════════
-- 6. Public read access — source directory stats only
-- Only aggregated stats, no sensitive fields
-- ═══════════════════════════════════════════════════════

CREATE POLICY "public_read_source_maturity"
  ON public.source_maturity
  FOR SELECT
  TO anon
  USING (true);

-- ═══════════════════════════════════════════════════════
-- 7. Block all writes from anon on sensitive tables
-- Explicit deny — prevents accidental anon key misuse
-- ═══════════════════════════════════════════════════════

-- No INSERT/UPDATE/DELETE policies for anon on:
-- sources, permissions, submissions, safety_flags, suggestions,
-- agent_sessions, agent_trust_scores, content_items,
-- ecosystem_updates, entity_profiles, general_chat_messages,
-- knowledge_gaps, chat_messages
-- → These tables have NO anon policies, so all writes are blocked by default.

-- ═══════════════════════════════════════════════════════
-- 8. Authenticated user policies (future-proofing)
-- For when we add JWT-based auth for dashboard users.
-- Authenticated users see tier 1-2 content up to their default_tier.
-- ═══════════════════════════════════════════════════════

-- Note: These use Supabase auth.uid(). Currently no users table exists,
-- so these are placeholders for future dashboard auth.

-- CREATE POLICY "auth_read_knowledge_units"
--   ON public.knowledge_units
--   FOR SELECT
--   TO authenticated
--   USING (tier <= 2 AND status = 'published');

-- CREATE POLICY "auth_read_submissions"
--   ON public.submissions
--   FOR SELECT
--   TO authenticated
--   USING (
--     EXISTS (
--       SELECT 1 FROM public.permissions p
--       WHERE p.source_id = submissions.source_id
--       AND p.user_id = auth.uid()
--     )
--   );

-- ═══════════════════════════════════════════════════════
-- 9. Verify: Check RLS is enabled
-- Run after migration: SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
-- All tables should show rowsecurity = true
-- ═══════════════════════════════════════════════════════
