-- Taxonomy Table: categories
-- Purpose: Controlled vocabulary for submission/knowledge_unit categories
-- Date: 2026-04-11

BEGIN;

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES categories(id),
  library_section TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);

COMMENT ON TABLE categories IS 'Controlled vocabulary for submission and knowledge_unit categories';
COMMENT ON COLUMN categories.library_section IS 'Which Society Libraries section this category maps to';

-- Seed with existing categories from RECON_BLUEPRINT.md
INSERT INTO categories (name, description, library_section) VALUES
  ('identity', 'Agent or project identity information', 'Getting Started'),
  ('build', 'Build process, stack, architecture', 'Build Guides'),
  ('operational', 'Operational data: uptime, errors, task results', 'Operator Strategies'),
  ('performance', 'Performance metrics, benchmarks, outcomes', 'Optimization Notes'),
  ('failure', 'What broke, why, what fixed it', 'Failure Patterns & Fixes'),
  ('knowledge', 'Tutorials, prompts, checklists, heuristics', 'Guides'),
  ('safety', 'Scam patterns, key exposure risks, unsafe practices', 'Safety & Key Management'),
  ('friction', 'Where people get stuck, repeated questions', 'FAQ / Common Confusion'),
  ('audit_request', 'Request for Recon analysis or audit', NULL)
ON CONFLICT (name) DO NOTHING;

COMMIT;
