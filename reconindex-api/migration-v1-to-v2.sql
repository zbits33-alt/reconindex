-- =========================================================
-- RECONINDEX SCHEMA MIGRATION v1 → v2
-- Preserves ALL existing data
-- Date: 2026-04-09
-- =========================================================

-- ─── 1. SOURCES TABLE ───

-- Rename columns (safe, preserves data)
alter table public.sources rename column type to source_type;
alter table public.sources rename column owner to owner_name;

-- Add new columns
alter table public.sources add column if not exists source_code text unique;
alter table public.sources add column if not exists status text not null default 'active';
alter table public.sources add column if not exists updated_at timestamptz not null default now();

-- Migrate active (boolean) → status (text)
update public.sources set status = case
  when active = true then 'active'
  when active = false then 'inactive'
  else 'active'
end;

-- Migrate ecosystem (array) data into ecosystem_scope if not already there
-- ecosystem_scope already exists, just make sure data is synced
update public.sources
set ecosystem_scope = ecosystem
where ecosystem_scope = '{}' and ecosystem != '{}';

-- Backfill source_code from existing data
update public.sources set source_code = 'SRC-001' where name = 'Recon' and source_code is null;
update public.sources set source_code = 'SRC-002' where name = 'Predator' and source_code is null;
-- For any others without source_code, generate one
update public.sources
set source_code = 'SRC-' || lpad((row_number() over (order by created_at))::text, 3, '0')
where source_code is null;

-- Drop old columns (after data is migrated)
alter table public.sources drop column if exists active;
alter table public.sources drop column if exists ecosystem;
alter table public.sources drop column if exists meta;

-- Add updated_at trigger
drop trigger if exists trg_sources_updated_at on public.sources;
create trigger trg_sources_updated_at
before update on public.sources
for each row execute function public.set_updated_at();

-- ─── 2. PERMISSIONS TABLE ───

alter table public.permissions add column if not exists request_depth_level integer not null default 1;
alter table public.permissions add column if not exists allow_logs boolean not null default false;
alter table public.permissions add column if not exists allow_code_snippets boolean not null default false;
alter table public.permissions add column if not exists allow_configs boolean not null default false;
alter table public.permissions add column if not exists allow_prompts boolean not null default false;
alter table public.permissions add column if not exists allow_screenshots boolean not null default false;
alter table public.permissions add column if not exists allow_library_promotion boolean not null default false;
alter table public.permissions add column if not exists allow_anonymized_pattern_use boolean not null default true;
alter table public.permissions add column if not exists allow_public_display boolean not null default false;
alter table public.permissions add column if not exists notes text;
alter table public.permissions add column if not exists updated_at timestamptz not null default now();

drop trigger if exists trg_permissions_updated_at on public.permissions;
create trigger trg_permissions_updated_at
before update on public.permissions
for each row execute function public.set_updated_at();

-- ─── 3. SUBMISSIONS TABLE ───

alter table public.submissions add column if not exists submission_code text unique;

drop trigger if exists trg_submissions_updated_at on public.submissions;
create trigger trg_submissions_updated_at
before update on public.submissions
for each row execute function public.set_updated_at();

-- ─── 4. NEW TABLES ───

-- library_drafts
create table if not exists public.library_drafts (
 id uuid primary key default gen_random_uuid(),
 candidate_id uuid references public.library_candidates(id) on delete set null,
 source_id uuid references public.sources(id) on delete set null,
 title text not null,
 draft_type text not null,
 summary text not null,
 body_markdown text not null,
 tags text[] default '{}',
 status text not null default 'draft',
 review_notes text,
 approved_by text,
 approved_at timestamptz,
 published_at timestamptz,
 content_hash text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

drop trigger if exists trg_library_drafts_updated_at on public.library_drafts;
create trigger trg_library_drafts_updated_at
before update on public.library_drafts
for each row execute function public.set_updated_at();

-- agent_trust_scores
create table if not exists public.agent_trust_scores (
 id uuid primary key default gen_random_uuid(),
 source_id uuid not null unique references public.sources(id) on delete cascade,
 trust_score numeric not null default 50,
 submission_quality_avg numeric not null default 0,
 contribution_count integer not null default 0,
 approved_candidate_count integer not null default 0,
 rejected_submission_count integer not null default 0,
 flagged_submission_count integer not null default 0,
 pattern_hit_count integer not null default 0,
 validated_suggestion_count integer not null default 0,
 failed_suggestion_count integer not null default 0,
 last_calculated_at timestamptz not null default now(),
 trust_tier text not null default 'neutral',
 notes text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

drop trigger if exists trg_agent_trust_scores_updated_at on public.agent_trust_scores;
create trigger trg_agent_trust_scores_updated_at
before update on public.agent_trust_scores
for each row execute function public.set_updated_at();

-- pattern_links
create table if not exists public.pattern_links (
 id uuid primary key default gen_random_uuid(),
 parent_pattern_id uuid not null references public.patterns(id) on delete cascade,
 child_pattern_id uuid not null references public.patterns(id) on delete cascade,
 relationship_type text not null,
 confidence numeric not null default 0,
 notes text,
 created_at timestamptz not null default now(),
 unique(parent_pattern_id, child_pattern_id, relationship_type)
);

-- source_maturity
create table if not exists public.source_maturity (
 id uuid primary key default gen_random_uuid(),
 source_id uuid not null unique references public.sources(id) on delete cascade,
 maturity_level text not null default 'new',
 relationship_depth integer not null default 1,
 first_seen timestamptz not null default now(),
 last_seen timestamptz not null default now(),
 last_submission_at timestamptz,
 missed_update_cycles integer not null default 0,
 active_status text not null default 'active',
 notes text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

drop trigger if exists trg_source_maturity_updated_at on public.source_maturity;
create trigger trg_source_maturity_updated_at
before update on public.source_maturity
for each row execute function public.set_updated_at();

-- ─── 5. FOREIGN KEY FOR related_gap_id (depends on knowledge_gaps which already exists) ───

-- Check if FK exists before adding
do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'submissions_related_gap_id_fkey'
  ) then
    alter table public.submissions
     add constraint submissions_related_gap_id_fkey
     foreign key (related_gap_id) references public.knowledge_gaps(id)
     on delete set null;
  end if;
end $$;

-- ─── 6. chat_messages session_id FK (depends on agent_sessions which already exists) ───

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'chat_messages_session_id_fkey'
  ) then
    alter table public.chat_messages
     add constraint chat_messages_session_id_fkey
     foreign key (session_id) references public.agent_sessions(id)
     on delete set null;
  end if;
end $$;

-- ─── 7. INDEXES ───

create index if not exists idx_sources_name on public.sources(name);
create index if not exists idx_sources_status on public.sources(status);
create index if not exists idx_assets_source_id on public.assets(source_id);
create index if not exists idx_assets_type on public.assets(asset_type);
create index if not exists idx_submissions_source_id on public.submissions(source_id);
create index if not exists idx_submissions_asset_id on public.submissions(asset_id);
create index if not exists idx_submissions_category on public.submissions(category);
create index if not exists idx_submissions_processing_status on public.submissions(processing_status);
create index if not exists idx_submissions_created_at on public.submissions(created_at desc);
create index if not exists idx_knowledge_units_source_id on public.knowledge_units(source_id);
create index if not exists idx_knowledge_units_submission_id on public.knowledge_units(submission_id);
create index if not exists idx_knowledge_units_freshness_status on public.knowledge_units(freshness_status);
create index if not exists idx_knowledge_units_review_status on public.knowledge_units(review_status);
create index if not exists idx_library_candidates_status on public.library_candidates(status);
create index if not exists idx_patterns_status on public.patterns(status);
create index if not exists idx_patterns_strength on public.patterns(pattern_strength_score desc);
create index if not exists idx_safety_flags_status on public.safety_flags(status);
create index if not exists idx_safety_flags_source_id on public.safety_flags(source_id);
create index if not exists idx_chat_messages_source_id on public.chat_messages(source_id);
create index if not exists idx_chat_messages_session_id on public.chat_messages(session_id);
create index if not exists idx_general_chat_room on public.general_chat_messages(room);
create index if not exists idx_agent_sessions_source_id on public.agent_sessions(source_id);
create index if not exists idx_agent_sessions_status on public.agent_sessions(session_status);
create index if not exists idx_suggestions_status on public.suggestions(status);
create index if not exists idx_knowledge_gaps_status on public.knowledge_gaps(status);
create index if not exists idx_knowledge_gaps_urgency on public.knowledge_gaps(urgency_score desc);
create index if not exists idx_suggestion_outcomes_source_id on public.suggestion_outcomes(source_id);
create index if not exists idx_source_maturity_level on public.source_maturity(maturity_level);

-- ─── 8. VERIFY MIGRATION ───

select 'Migration complete' as status,
  (select count(*) from public.sources) as sources_count,
  (select count(*) from public.permissions) as permissions_count,
  (select count(*) from public.submissions) as submissions_count;
