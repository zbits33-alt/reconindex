-- Recon Index — Phase 1 Schema
-- Applied via Supabase CLI

CREATE EXTENSION IF NOT EXISTS vector;

-- 1. SOURCES
CREATE TABLE sources (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  type          TEXT NOT NULL CHECK (type IN (
                  'agent', 'bot', 'tool', 'workflow',
                  'human', 'data_source', 'documentation'
                )),
  owner         TEXT,
  ecosystem     TEXT[],
  api_token     TEXT UNIQUE NOT NULL,
  active        BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  meta          JSONB DEFAULT '{}'
);

-- 2. PERMISSIONS
CREATE TABLE permissions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id       UUID REFERENCES sources(id) ON DELETE CASCADE,
  default_tier    SMALLINT NOT NULL DEFAULT 2 CHECK (default_tier BETWEEN 1 AND 4),
  allow_logs      BOOLEAN DEFAULT FALSE,
  allow_screenshots BOOLEAN DEFAULT FALSE,
  allow_code      BOOLEAN DEFAULT FALSE,
  allow_prompts   BOOLEAN DEFAULT FALSE,
  allow_configs   BOOLEAN DEFAULT FALSE,
  allow_perf_data BOOLEAN DEFAULT FALSE,
  allow_anonymized_sharing BOOLEAN DEFAULT TRUE,
  allow_library_promotion  BOOLEAN DEFAULT FALSE,
  never_store     TEXT[],
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ASSETS
CREATE TABLE assets (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id     UUID REFERENCES sources(id) ON DELETE SET NULL,
  name          TEXT NOT NULL,
  asset_type    TEXT NOT NULL CHECK (asset_type IN (
                  'agent', 'project', 'workflow', 'guide',
                  'dataset', 'incident', 'tool', 'strategy'
                )),
  description   TEXT,
  ecosystem     TEXT[],
  stage         TEXT CHECK (stage IN (
                  'concept', 'prototype', 'testing', 'live', 'deprecated'
                )),
  stack         TEXT[],
  hosting       TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  meta          JSONB DEFAULT '{}'
);

-- 4. SUBMISSIONS
CREATE TABLE submissions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id       UUID REFERENCES sources(id) ON DELETE SET NULL,
  asset_id        UUID REFERENCES assets(id) ON DELETE SET NULL,
  submitted_at    TIMESTAMPTZ DEFAULT NOW(),
  tier            SMALLINT NOT NULL DEFAULT 2 CHECK (tier BETWEEN 1 AND 4),
  category        TEXT NOT NULL CHECK (category IN (
                    'identity', 'build', 'operational', 'performance',
                    'failure', 'knowledge', 'safety', 'friction', 'audit_request'
                  )),
  summary         TEXT,
  content         TEXT,
  r2_keys         TEXT[],
  status          TEXT DEFAULT 'received' CHECK (status IN (
                    'received', 'processing', 'classified',
                    'flagged', 'archived', 'rejected'
                  )),
  usefulness_score SMALLINT,
  meta            JSONB DEFAULT '{}'
);

-- 5. KNOWLEDGE UNITS
CREATE TABLE knowledge_units (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id   UUID REFERENCES submissions(id) ON DELETE SET NULL,
  source_id       UUID REFERENCES sources(id) ON DELETE SET NULL,
  tier            SMALLINT NOT NULL CHECK (tier BETWEEN 1 AND 4),
  category        TEXT NOT NULL,
  title           TEXT NOT NULL,
  summary         TEXT NOT NULL,
  key_insight     TEXT NOT NULL,
  tags            TEXT[],
  usefulness_score SMALLINT CHECK (usefulness_score BETWEEN 1 AND 10),
  repeat_count    INT DEFAULT 1,
  library_candidate BOOLEAN DEFAULT FALSE,
  embedding       VECTOR(1536),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 6. LIBRARY CANDIDATES
CREATE TABLE library_candidates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  knowledge_unit_id UUID REFERENCES knowledge_units(id) ON DELETE CASCADE,
  draft_title     TEXT NOT NULL,
  draft_content   TEXT NOT NULL,
  category        TEXT,
  review_status   TEXT DEFAULT 'pending' CHECK (review_status IN (
                    'pending', 'approved', 'rejected', 'needs_revision'
                  )),
  reviewer_notes  TEXT,
  published_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 7. PATTERNS
CREATE TABLE patterns (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pattern_type    TEXT NOT NULL CHECK (pattern_type IN (
                    'failure', 'fix', 'friction', 'success',
                    'safety', 'architecture', 'workflow'
                  )),
  title           TEXT NOT NULL,
  description     TEXT,
  occurrence_count INT DEFAULT 1,
  first_seen      TIMESTAMPTZ DEFAULT NOW(),
  last_seen       TIMESTAMPTZ DEFAULT NOW(),
  linked_units    UUID[],
  tags            TEXT[]
);

-- 8. SAFETY FLAGS
CREATE TABLE safety_flags (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id   UUID REFERENCES submissions(id) ON DELETE CASCADE,
  source_id       UUID REFERENCES sources(id) ON DELETE SET NULL,
  flag_type       TEXT NOT NULL CHECK (flag_type IN (
                    'secret_exposure', 'unsafe_practice', 'privacy_violation',
                    'scam_pattern', 'suspicious_dependency', 'social_engineering',
                    'policy_violation', 'other'
                  )),
  severity        TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  description     TEXT,
  resolved        BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES
CREATE INDEX idx_submissions_source    ON submissions(source_id);
CREATE INDEX idx_submissions_status    ON submissions(status);
CREATE INDEX idx_submissions_category  ON submissions(category);
CREATE INDEX idx_knowledge_units_tier  ON knowledge_units(tier);
CREATE INDEX idx_knowledge_units_tags  ON knowledge_units USING GIN(tags);
CREATE INDEX idx_patterns_type         ON patterns(pattern_type);
CREATE INDEX idx_safety_flags_severity ON safety_flags(severity) WHERE resolved = FALSE;
