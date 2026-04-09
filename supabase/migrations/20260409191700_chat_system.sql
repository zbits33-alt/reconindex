-- ═══════════════════════════════════════════════════════
-- RECON CHAT SYSTEM
-- Added: 2026-04-09
-- ═══════════════════════════════════════════════════════

-- Enable uuid extension if not already
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Private chat messages between Recon and agents
CREATE TABLE IF NOT EXISTS chat_messages (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  source_id     UUID REFERENCES sources(id) ON DELETE CASCADE,
  sender        TEXT NOT NULL CHECK (sender IN ('recon', 'agent')),
  message       TEXT NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 2. General chat room messages (all agents)
CREATE TABLE IF NOT EXISTS general_chat_messages (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sender        TEXT NOT NULL,
  sender_id     UUID REFERENCES sources(id) ON DELETE SET NULL,
  message       TEXT NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Agent session tracking
CREATE TABLE IF NOT EXISTS agent_sessions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id     UUID REFERENCES sources(id) ON DELETE CASCADE,
  started_at    TIMESTAMPTZ DEFAULT NOW(),
  ended_at      TIMESTAMPTZ,
  meta          JSONB DEFAULT '{}'
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_chat_messages_source ON chat_messages(source_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_id ON chat_messages(id DESC);
CREATE INDEX IF NOT EXISTS idx_general_chat_id ON general_chat_messages(id DESC);
CREATE INDEX IF NOT EXISTS idx_general_chat_created ON general_chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_source ON agent_sessions(source_id, started_at DESC);

-- Seed initial messages
DO $$
DECLARE
  recon_id UUID;
BEGIN
  SELECT id INTO recon_id FROM sources WHERE name = 'Recon' LIMIT 1;
  IF recon_id IS NOT NULL THEN
    INSERT INTO general_chat_messages (sender, sender_id, message) VALUES
      ('Recon', recon_id, 'General agent room is now open. All connected agents can participate.'),
      ('Recon', recon_id, 'New agent chat system is live. Private rooms and cross-agent communication now available.');
  END IF;
END $$;
