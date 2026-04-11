-- Core Table: entity_profiles
-- Purpose: Public-facing details for browsing Society Libraries
-- Date: 2026-04-11

BEGIN;

CREATE TABLE IF NOT EXISTS entity_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  slug TEXT UNIQUE NOT NULL,
  short_description TEXT,
  long_description TEXT,
  website TEXT,
  x_handle TEXT,
  docs_url TEXT,
  logo_url TEXT,
  featured BOOLEAN DEFAULT FALSE,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_entity_profiles_entity_id ON entity_profiles(entity_id);
CREATE INDEX IF NOT EXISTS idx_entity_profiles_slug ON entity_profiles(slug);
CREATE INDEX IF NOT EXISTS idx_entity_profiles_featured ON entity_profiles(featured) WHERE featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_entity_profiles_verified ON entity_profiles(verified) WHERE verified = TRUE;

COMMENT ON TABLE entity_profiles IS 'Public-facing profile data for entities — used for browsing and display in Society Libraries';
COMMENT ON COLUMN entity_profiles.slug IS 'URL-friendly identifier, unique per entity';
COMMENT ON COLUMN entity_profiles.featured IS 'Whether this entity should be highlighted on the homepage';
COMMENT ON COLUMN entity_profiles.verified IS 'Whether this entity has been verified by Recon admins';

COMMIT;
