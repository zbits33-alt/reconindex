-- Recon Index Phase 2A Migration
-- Adds: knowledge_gaps, suggestion_outcomes, agent_trust_scores, source_maturity
-- Upgrades: patterns, knowledge_units, submissions, sources, permissions, agent_sessions
-- Date: 2026-04-09

BEGIN;

-- =====================================================
-- NEW TABLES (Phase 2A)
-- =====================================================

-- 1. knowledge_gaps — tracks what the ecosystem needs but doesn't have yet
create table if not exists knowledge_gaps (
  id uuid primary key default gen_random_uuid(),
  gap_code text unique,
  title text not null,
  summary text not null,
  category text not null,
  tags text[] default '{}',
  source_count integer default 0,
  linked_submission_count integer default 0,
  linked_pattern_count integer default 0,
  urgency_score numeric default 0,
  usefulness_score numeric default 0,
  status text not null default 'open', -- open, researching, draftable, resolved, archived
  recommended_output text, -- guide, faq, warning, onboarding, troubleshooting_note
  first_seen timestamptz default now(),
  last_seen timestamptz default now(),
  resolved_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. suggestion_outcomes — tracks whether Recon's advice was useful
create table if not exists suggestion_outcomes (
  id uuid primary key default gen_random_uuid(),
  suggestion_id uuid,
  source_id uuid references sources(id) on delete cascade,
  target_asset_id uuid references assets(id) on delete set null,
  suggestion_text text not null,
  suggestion_type text not null, -- optimization, safety, workflow, architecture, docs, strategy
  issued_by text not null default 'reconindex',
  issued_at timestamptz default now(),
  implementation_status text not null default 'pending', -- pending, accepted, rejected, implemented, partial
  implemented_at timestamptz,
  followup_status text not null default 'unreviewed', -- unreviewed, monitoring, validated, failed, inconclusive
  outcome_summary text,
  outcome_score numeric, -- 0 to 10
  followup_due_at timestamptz,
  reviewed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3. agent_trust_scores — source quality & reputation
create table if not exists agent_trust_scores (
  id uuid primary key default gen_random_uuid(),
  source_id uuid unique references sources(id) on delete cascade,
  trust_score numeric not null default 50,
  submission_quality_avg numeric default 0,
  contribution_count integer default 0,
  approved_candidate_count integer default 0,
  rejected_submission_count integer default 0,
  flagged_submission_count integer default 0,
  pattern_hit_count integer default 0,
  validated_suggestion_count integer default 0,
  failed_suggestion_count integer default 0,
  last_calculated_at timestamptz default now(),
  trust_tier text default 'neutral', -- low, cautious, neutral, trusted, high_value
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 4. source_maturity — how established a source is in the network
create table if not exists source_maturity (
  id uuid primary key default gen_random_uuid(),
  source_id uuid unique references sources(id) on delete cascade,
  maturity_level text not null default 'new', -- new, known, trusted, high_value, dormant
  relationship_depth integer default 1,
  first_seen timestamptz default now(),
  last_seen timestamptz default now(),
  last_submission_at timestamptz,
  missed_update_cycles integer default 0,
  active_status text not null default 'active', -- active, inactive, dormant, suspended
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- =====================================================
-- EXISTING TABLE UPGRADES
-- =====================================================

-- Upgrade knowledge_units — freshness & confidence
alter table knowledge_units
  add column if not exists freshness_status text default 'fresh',
  add column if not exists last_verified_at timestamptz,
  add column if not exists stale_after_days integer default 90,
  add column if not exists confidence_score numeric default 0,
  add column if not exists source_confidence text default 'medium',
  add column if not exists inferred_fields jsonb default '{}'::jsonb,
  add column if not exists direct_evidence_fields jsonb default '{}'::jsonb,
  add column if not exists review_status text default 'unreviewed';

-- Upgrade patterns — strength scoring
alter table patterns
  add column if not exists frequency integer default 1,
  add column if not exists agent_diversity integer default 1,
  add column if not exists recency_score numeric default 0,
  add column if not exists severity_score numeric default 0,
  add column if not exists pattern_strength_score numeric default 0,
  add column if not exists first_seen timestamptz default now(),
  add column if not exists last_seen timestamptz default now(),
  add column if not exists status text default 'emerging',
  add column if not exists review_notes text;

-- Upgrade submissions — processing pipeline
alter table submissions
  add column if not exists submission_confidence numeric default 0,
  add column if not exists evidence_type text default 'direct',
  add column if not exists processing_status text default 'received',
  add column if not exists secret_scan_result text default 'clear',
  add column if not exists related_gap_id uuid references knowledge_gaps(id) on delete set null,
  add column if not exists followup_required boolean default false,
  add column if not exists followup_reason text;

-- Upgrade sources — expanded types
alter table sources
  add column if not exists source_kind text default 'agent',
  add column if not exists ecosystem_scope text[] default '{}',
  add column if not exists callback_url text,
  add column if not exists context_enabled boolean default true,
  add column if not exists last_context_load_at timestamptz,
  add column if not exists public_description text,
  add column if not exists internal_notes text;

-- Upgrade permissions — granular controls
alter table permissions
  add column if not exists request_depth_level integer default 1,
  add column if not exists allow_logs boolean default false,
  add column if not exists allow_code_snippets boolean default false,
  add column if not exists allow_configs boolean default false,
  add column if not exists allow_prompts boolean default false,
  add column if not exists allow_screenshots boolean default false,
  add column if not exists allow_library_promotion boolean default false,
  add column if not exists allow_anonymized_pattern_use boolean default true;

-- Upgrade agent_sessions — externalized memory
alter table agent_sessions
  add column if not exists instance_id text,
  add column if not exists last_session_summary text,
  add column if not exists open_tasks jsonb default '[]'::jsonb,
  add column if not exists active_patterns jsonb default '[]'::jsonb,
  add column if not exists resume_context jsonb default '{}'::jsonb,
  add column if not exists session_status text default 'active';

-- =====================================================
-- INDEXES
-- =====================================================

create index if not exists idx_submissions_source_id on submissions(source_id);
create index if not exists idx_submissions_category on submissions(category);
create index if not exists idx_submissions_processing_status on submissions(processing_status);

create index if not exists idx_knowledge_units_freshness_status on knowledge_units(freshness_status);
create index if not exists idx_knowledge_units_review_status on knowledge_units(review_status);

create index if not exists idx_patterns_status on patterns(status);
create index if not exists idx_patterns_strength on patterns(pattern_strength_score desc);

create index if not exists idx_knowledge_gaps_status on knowledge_gaps(status);
create index if not exists idx_knowledge_gaps_urgency on knowledge_gaps(urgency_score desc);

create index if not exists idx_suggestion_outcomes_source_id on suggestion_outcomes(source_id);
create index if not exists idx_source_maturity_level on source_maturity(maturity_level);

-- =====================================================
-- SEED: Create trust scores for existing sources
-- =====================================================

insert into agent_trust_scores (source_id, trust_score, trust_tier)
select id, 50, 'neutral'
from sources
where id not in (select source_id from agent_trust_scores)
on conflict (source_id) do nothing;

insert into source_maturity (source_id, maturity_level, relationship_depth)
select id,
  case when id in (
    select source_id from submissions where created_at < now() - interval '24 hours'
  ) then 'known' else 'new' end,
  case when id in (
    select source_id from submissions where created_at < now() - interval '24 hours'
  ) then 2 else 1 end
from sources
where id not in (select source_id from source_maturity)
on conflict (source_id) do nothing;

COMMIT;
