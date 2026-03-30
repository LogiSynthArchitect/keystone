-- ============================================================
-- V2 Security Fixes — Wave 2 — 2026-03-30
-- Applied to DEV on: 2026-03-30
-- Apply to PRODUCTION before launch
-- ============================================================
-- Fixes:
--   FIX 14: Create key_code_history table + RLS (was missing entirely)
--   FIX 19: Job photos storage RLS (owner-only read/write/delete)
--   FIX 24: Reserved slug blacklist on users.profile_slug
--   FIX 25: Suspended users blocked from jobs + notes within JWT window
-- ============================================================

-- ------------------------------------------------------------
-- FIX 14: Create key_code_history table
-- Table was missing — key codes were Hive-only with no remote backup.
-- Remote datasource was silently failing on every sync attempt.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.key_code_history (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id   uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  job_id        uuid REFERENCES public.jobs(id) ON DELETE SET NULL,
  key_code      text NOT NULL,
  key_type      text,
  bitting_data  text, -- stored AES-256-GCM encrypted by Flutter client
  description   text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz
);

CREATE OR REPLACE FUNCTION set_key_code_user_id()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  NEW.user_id := auth.uid();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_set_key_code_user_id
BEFORE INSERT ON public.key_code_history
FOR EACH ROW EXECUTE FUNCTION set_key_code_user_id();

ALTER TABLE public.key_code_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "key_codes_select_own"
ON key_code_history FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "key_codes_insert_own"
ON key_code_history FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "key_codes_update_own"
ON key_code_history FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "key_codes_delete_own"
ON key_code_history FOR DELETE TO authenticated
USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_key_code_history_customer
ON public.key_code_history(customer_id);

-- ------------------------------------------------------------
-- FIX 19: Job photos storage RLS
-- Bucket 'job-photos' — owner-only access.
-- ⚠️  ALSO set bucket to PRIVATE in Supabase Storage dashboard.
-- ⚠️  Flutter must migrate from getPublicUrl() → createSignedUrl()
--     after bucket is made private (tracked as pending code fix).
-- ------------------------------------------------------------

CREATE POLICY "storage_job_photos_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'job-photos'
  AND (auth.uid())::text = (storage.foldername(name))[1]
);

CREATE POLICY "storage_job_photos_read"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'job-photos'
  AND (auth.uid())::text = (storage.foldername(name))[1]
);

CREATE POLICY "storage_job_photos_delete"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'job-photos'
  AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- ------------------------------------------------------------
-- FIX 25: Suspended users blocked from jobs + notes
-- Jobs and notes RLS now checks users.status = 'active'
-- Closes the ~60-minute JWT window after suspension
-- ------------------------------------------------------------

DROP POLICY IF EXISTS "jobs_select_own" ON jobs;
DROP POLICY IF EXISTS "jobs_insert_own" ON jobs;
DROP POLICY IF EXISTS "jobs_update_own" ON jobs;

CREATE POLICY "jobs_select_own"
ON jobs FOR SELECT TO authenticated
USING (
  user_id IN (SELECT id FROM users WHERE auth_id = auth.uid() AND status = 'active')
);

CREATE POLICY "jobs_insert_own"
ON jobs FOR INSERT TO authenticated
WITH CHECK (
  user_id IN (SELECT id FROM users WHERE auth_id = auth.uid() AND status = 'active')
);

CREATE POLICY "jobs_update_own"
ON jobs FOR UPDATE TO authenticated
USING (
  user_id IN (SELECT id FROM users WHERE auth_id = auth.uid() AND status = 'active')
);

DROP POLICY IF EXISTS "notes_select_own" ON knowledge_notes;
DROP POLICY IF EXISTS "notes_insert_own" ON knowledge_notes;
DROP POLICY IF EXISTS "notes_update_own" ON knowledge_notes;
DROP POLICY IF EXISTS "notes_delete_own" ON knowledge_notes;

CREATE POLICY "notes_select_own"
ON knowledge_notes FOR SELECT TO authenticated
USING (auth.uid() = user_id AND EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND status = 'active'
));

CREATE POLICY "notes_insert_own"
ON knowledge_notes FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id AND EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND status = 'active'
));

CREATE POLICY "notes_update_own"
ON knowledge_notes FOR UPDATE TO authenticated
USING (auth.uid() = user_id AND EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND status = 'active'
));

CREATE POLICY "notes_delete_own"
ON knowledge_notes FOR DELETE TO authenticated
USING (auth.uid() = user_id AND EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND status = 'active'
));

-- ------------------------------------------------------------
-- FIX 24: Reserved slug blacklist
-- Prevents technicians claiming admin, api, _next, etc.
-- ------------------------------------------------------------

ALTER TABLE users
DROP CONSTRAINT IF EXISTS users_profile_slug_not_reserved;

ALTER TABLE users
ADD CONSTRAINT users_profile_slug_not_reserved
CHECK (
  profile_slug NOT IN (
    'admin','api','app','auth','login','logout','register',
    'signup','settings','dashboard','support','help','legal',
    'privacy','terms','about','contact','null','undefined',
    '_next','static','favicon.ico','robots.txt','sitemap.xml',
    'p','profile','profiles','user','users'
  )
);
