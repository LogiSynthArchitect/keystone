-- ============================================================
-- V2 Security Fixes — 2026-03-30
-- Applied to DEV on: 2026-03-30
-- Apply to PRODUCTION before launch
-- ============================================================
-- Fixes:
--   FIX 3: Suspended users no longer served on public profile page
--   FIX 1: Server-side permission enforcement via permissions JSONB column
-- ============================================================

-- ------------------------------------------------------------
-- FIX 3: Replace anon/authenticated profile read policies
-- to exclude suspended users from public profile visibility
-- ------------------------------------------------------------

DROP POLICY IF EXISTS "Allow anon users to read public profiles" ON profiles;
DROP POLICY IF EXISTS "Allow authenticated users to read public profiles" ON profiles;

CREATE POLICY "Allow anon users to read active public profiles"
ON profiles FOR SELECT
TO anon
USING (
  is_public = true
  AND EXISTS (
    SELECT 1 FROM users
    WHERE users.auth_id = profiles.user_id
    AND users.status = 'active'
  )
);

CREATE POLICY "Allow authenticated users to read active public profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  is_public = true
  AND (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = profiles.user_id
      AND users.status = 'active'
    )
  )
);

-- ------------------------------------------------------------
-- FIX 1: Add permissions JSONB column to users table
-- Stores per-user permission overrides set by admin
-- Defaults to full access (true) for all permissions
-- ------------------------------------------------------------

ALTER TABLE users
ADD COLUMN IF NOT EXISTS permissions JSONB NOT NULL DEFAULT '{
  "can_edit_final_price": true,
  "can_delete_jobs": true,
  "can_view_key_codes": true
}'::jsonb;

-- Only admins can update the permissions column
CREATE POLICY "admin_can_update_user_permissions"
ON users FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users AS me
    WHERE me.auth_id = auth.uid()
    AND me.role = 'admin'
  )
)
WITH CHECK (true);

-- Helper function: check if current user can edit final price
CREATE OR REPLACE FUNCTION check_can_edit_final_price()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (permissions->>'can_edit_final_price')::boolean,
    true
  )
  FROM users
  WHERE auth_id = auth.uid();
$$;

-- Helper function: check if current user can delete/archive jobs
CREATE OR REPLACE FUNCTION check_can_delete_jobs()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (permissions->>'can_delete_jobs')::boolean,
    true
  )
  FROM users
  WHERE auth_id = auth.uid();
$$;
