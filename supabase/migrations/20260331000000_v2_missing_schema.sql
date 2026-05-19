-- ============================================================
-- V2 Missing Schema — 2026-03-31
-- Applied to DEV on: 2026-03-31
-- Apply to PRODUCTION before launch
-- ============================================================
-- Adds all V2 features that were built in Flutter but never
-- had corresponding DB migrations applied.
--
-- Tables created:
--   service_types, job_parts, job_audit_log, note_job_links
--
-- Columns added:
--   jobs: status, payment_status, is_deleted, sync_error_message
--   follow_ups: response_status
--
-- Policies added:
--   follow_ups: UPDATE own
--   job_parts: SELECT admin
--   note_job_links: SELECT admin
--   service_types: full CRUD (admin write, authenticated read)
--
-- Triggers:
--   service_types: updated_at auto-update
-- ============================================================


-- ------------------------------------------------------------
-- 1. Add missing columns to jobs
-- ------------------------------------------------------------

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'in_progress'
    CONSTRAINT jobs_status_check CHECK (status IN ('pending', 'in_progress', 'completed')),
  ADD COLUMN IF NOT EXISTS payment_status text NOT NULL DEFAULT 'unpaid'
    CONSTRAINT jobs_payment_status_check CHECK (payment_status IN ('unpaid', 'partial', 'paid')),
  ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sync_error_message text;


-- ------------------------------------------------------------
-- 2. Add response_status to follow_ups (Feature 24)
-- ------------------------------------------------------------

ALTER TABLE public.follow_ups
  ADD COLUMN IF NOT EXISTS response_status text NOT NULL DEFAULT 'sent'
    CONSTRAINT follow_ups_response_status_check
    CHECK (response_status IN ('sent', 'responded', 'no_response'));

-- Missing UPDATE policy — needed for response status updates
CREATE POLICY "followups_update_own"
ON public.follow_ups FOR UPDATE TO authenticated
USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()))
WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));


-- ------------------------------------------------------------
-- 3. service_types table
-- Shared global list. All authenticated users can read.
-- Only admins can write.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.service_types (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        text NOT NULL,
  is_default  boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.service_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_types_select_all"
ON public.service_types FOR SELECT TO authenticated
USING (true);

CREATE POLICY "service_types_insert_admin"
ON public.service_types FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "service_types_update_admin"
ON public.service_types FOR UPDATE TO authenticated
USING (EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "service_types_delete_admin"
ON public.service_types FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'admin'
));

CREATE INDEX IF NOT EXISTS idx_service_types_user ON public.service_types(user_id);

CREATE TRIGGER set_service_types_updated_at
BEFORE UPDATE ON public.service_types
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ------------------------------------------------------------
-- 4. job_parts table (V2 Phase 2)
-- Parts/materials used on a job. Owned by the job owner.
-- unit_price stored as decimal (GHS), Flutter converts to/from pesewas.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.job_parts (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id      uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  part_name   text NOT NULL,
  quantity    integer,
  unit_price  numeric(10,2),
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.job_parts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "job_parts_select_own"
ON public.job_parts FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM jobs WHERE jobs.id = job_id
  AND jobs.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE POLICY "job_parts_select_admin"
ON public.job_parts FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "job_parts_insert_own"
ON public.job_parts FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM jobs WHERE jobs.id = job_id
  AND jobs.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE POLICY "job_parts_update_own"
ON public.job_parts FOR UPDATE TO authenticated
USING (EXISTS (
  SELECT 1 FROM jobs WHERE jobs.id = job_id
  AND jobs.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE POLICY "job_parts_delete_own"
ON public.job_parts FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM jobs WHERE jobs.id = job_id
  AND jobs.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE INDEX IF NOT EXISTS idx_job_parts_job ON public.job_parts(job_id);


-- ------------------------------------------------------------
-- 5. job_audit_log table (V2 Phase 3)
-- Immutable append-only log of job field changes.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.job_audit_log (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id      uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  user_id     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action      text NOT NULL,
  old_values  jsonb,
  new_values  jsonb,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.job_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_log_select_own"
ON public.job_audit_log FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM jobs WHERE jobs.id = job_id
  AND jobs.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE POLICY "audit_log_select_admin"
ON public.job_audit_log FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "audit_log_insert_own"
ON public.job_audit_log FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM jobs WHERE jobs.id = job_id
  AND jobs.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE INDEX IF NOT EXISTS idx_audit_log_job ON public.job_audit_log(job_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON public.job_audit_log(user_id);


-- ------------------------------------------------------------
-- 6. note_job_links table (V2 Phase 5)
-- Links knowledge notes to jobs. One note can link to many jobs.
-- Unique constraint prevents duplicate links.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.note_job_links (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id     uuid NOT NULL REFERENCES public.knowledge_notes(id) ON DELETE CASCADE,
  job_id      uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  user_id     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT note_job_links_unique UNIQUE (note_id, job_id)
);

ALTER TABLE public.note_job_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "note_links_select_own"
ON public.note_job_links FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM knowledge_notes
  WHERE knowledge_notes.id = note_id
  AND knowledge_notes.user_id = auth.uid()
));

CREATE POLICY "note_links_select_admin"
ON public.note_job_links FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "note_links_insert_own"
ON public.note_job_links FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM knowledge_notes
  WHERE knowledge_notes.id = note_id
  AND knowledge_notes.user_id = auth.uid()
));

CREATE POLICY "note_links_delete_own"
ON public.note_job_links FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM knowledge_notes
  WHERE knowledge_notes.id = note_id
  AND knowledge_notes.user_id = auth.uid()
));

CREATE INDEX IF NOT EXISTS idx_note_links_note ON public.note_job_links(note_id);
CREATE INDEX IF NOT EXISTS idx_note_links_job ON public.note_job_links(job_id);
