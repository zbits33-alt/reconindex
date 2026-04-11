-- Add owner_access_code column to sources table
alter table public.sources add column if not exists owner_access_code text unique;

-- Backfill existing sources with access codes
update public.sources 
set owner_access_code = 'OWN-' || upper(substring(name from 1 for 8)) || '-' || substring(md5(id::text) from 1 for 6)
where owner_access_code is null;

-- Add index for faster lookups
create index if not exists idx_sources_owner_access_code on public.sources(owner_access_code);
