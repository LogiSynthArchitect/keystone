-- Migration: Password Auth Upgrade
-- Adds password_reset_codes table for self-service password recovery
-- Adds needs_password_upgrade flag for existing phone-only users

-- Password reset codes (used by Edge Function)
CREATE TABLE IF NOT EXISTS password_reset_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  phone TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT now() + interval '5 minutes',
  used BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for quick lookup by phone + code
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_phone_code
  ON password_reset_codes (phone, code);

-- Auto-cleanup expired codes
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_expires
  ON password_reset_codes (expires_at);

-- RLS: Only service role can access (Edge Function)
ALTER TABLE password_reset_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_access" ON password_reset_codes
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
