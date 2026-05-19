-- ============================================================
-- V2 Complete Schema — 2026-04-01
-- Applied to DEV: step by step (confirmed per step)
-- Apply to PRODUCTION before launch
-- ============================================================
-- What this migration adds:
--
-- Columns added:
--   jobs: payment_method, quoted_price, hardware_brand,
--         hardware_keyway, deleted_at
--   customers: lead_source, property_type
--
-- permissions default updated:
--   users: can_manage_service_types, can_view_all_technician_data
--
-- Tables created:
--   customer_audit_entries (with RLS)
--   job_photos             (with RLS)
--   reminders              (with RLS)
--
-- Functions replaced:
--   batch_sync_jobs — now handles all V2 job fields
-- ============================================================


-- ------------------------------------------------------------
-- STEP 1: Add missing V2 columns to jobs
-- ------------------------------------------------------------
-- (Applied to DEV: 2026-04-01 ✓)

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS payment_method  text,
  ADD COLUMN IF NOT EXISTS quoted_price    numeric(12,2),
  ADD COLUMN IF NOT EXISTS hardware_brand  text,
  ADD COLUMN IF NOT EXISTS hardware_keyway text,
  ADD COLUMN IF NOT EXISTS deleted_at      timestamptz;


-- ------------------------------------------------------------
-- STEP 2: Add missing V2 columns to customers
-- ------------------------------------------------------------
-- (Applied to DEV: 2026-04-01 ✓)

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS lead_source   text,
  ADD COLUMN IF NOT EXISTS property_type text;


-- ------------------------------------------------------------
-- STEP 3: Update users.permissions default + patch existing rows
-- ------------------------------------------------------------
-- (Applied to DEV: 2026-04-01 ✓)

-- Update the column default so all new users get all 5 keys
ALTER TABLE public.users
  ALTER COLUMN permissions
  SET DEFAULT '{"can_delete_jobs": true, "can_view_key_codes": true, "can_edit_final_price": true, "can_manage_service_types": false, "can_view_all_technician_data": false}'::jsonb;

-- Patch existing rows: merge in the two new keys without overwriting existing values
UPDATE public.users
SET permissions = permissions
  || '{"can_manage_service_types": false, "can_view_all_technician_data": false}'::jsonb
WHERE NOT (permissions ? 'can_manage_service_types')
   OR NOT (permissions ? 'can_view_all_technician_data');


-- ------------------------------------------------------------
-- STEP 4: customer_audit_entries table
-- Append-only log of customer field edits.
-- Scoped to the customer owner. Admins can read all.
-- ------------------------------------------------------------
-- (Applied to DEV: 2026-04-01 ✓)

CREATE TABLE IF NOT EXISTS public.customer_audit_entries (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  field_name  text NOT NULL,
  old_value   text,
  new_value   text,
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.customer_audit_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "customer_audit_select_own"
ON public.customer_audit_entries FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM customers
  WHERE customers.id = customer_id
    AND customers.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE POLICY "customer_audit_select_admin"
ON public.customer_audit_entries FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "customer_audit_insert_own"
ON public.customer_audit_entries FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM customers
  WHERE customers.id = customer_id
    AND customers.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE INDEX IF NOT EXISTS idx_customer_audit_customer
  ON public.customer_audit_entries(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_audit_created
  ON public.customer_audit_entries(created_at DESC);


-- ------------------------------------------------------------
-- STEP 5: job_photos table
-- Photo evidence attached to a job. Stored in 'job-photos' bucket.
-- Scoped to the job owner. Admins can read all.
-- ------------------------------------------------------------
-- (Applied to DEV: 2026-04-01 ✓)

CREATE TABLE IF NOT EXISTS public.job_photos (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id       uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  label        text,
  created_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.job_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "job_photos_select_own"
ON public.job_photos FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM jobs
  WHERE jobs.id = job_id
    AND jobs.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE POLICY "job_photos_select_admin"
ON public.job_photos FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "job_photos_insert_own"
ON public.job_photos FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM jobs
  WHERE jobs.id = job_id
    AND jobs.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE POLICY "job_photos_delete_own"
ON public.job_photos FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM jobs
  WHERE jobs.id = job_id
    AND jobs.user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
));

CREATE INDEX IF NOT EXISTS idx_job_photos_job
  ON public.job_photos(job_id);


-- ------------------------------------------------------------
-- STEP 6: reminders table
-- Smart reminders generated for unpaid/stuck jobs.
-- Strictly user-scoped. No admin read (personal workflow data).
-- ------------------------------------------------------------
-- (Applied to DEV: 2026-04-01 ✓)

CREATE TABLE IF NOT EXISTS public.reminders (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  job_id       uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  type         text NOT NULL
    CONSTRAINT reminders_type_check CHECK (
      type IN ('unpaid_job', 'stuck_in_progress', 'followup_pending', 'followup_no_response')
    ),
  status       text NOT NULL DEFAULT 'active'
    CONSTRAINT reminders_status_check CHECK (
      status IN ('active', 'dismissed', 'snoozed', 'resolved')
    ),
  created_at   timestamptz NOT NULL DEFAULT now(),
  snoozed_until timestamptz,
  dismissed_at  timestamptz
);

ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reminders_select_own"
ON public.reminders FOR SELECT TO authenticated
USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "reminders_insert_own"
ON public.reminders FOR INSERT TO authenticated
WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "reminders_update_own"
ON public.reminders FOR UPDATE TO authenticated
USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()))
WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "reminders_delete_own"
ON public.reminders FOR DELETE TO authenticated
USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE INDEX IF NOT EXISTS idx_reminders_user
  ON public.reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_job
  ON public.reminders(job_id);
CREATE INDEX IF NOT EXISTS idx_reminders_status
  ON public.reminders(user_id, status) WHERE status = 'active';


-- ------------------------------------------------------------
-- STEP 7: Replace batch_sync_jobs — add all V2 fields
-- ------------------------------------------------------------
-- (Applied to DEV: 2026-04-01 ✓)

CREATE OR REPLACE FUNCTION public.batch_sync_jobs(p_user_id uuid, p_jobs jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  job_record   jsonb;
  new_job_id   uuid;
  synced_jobs  jsonb := '[]';
  failed_jobs  jsonb := '[]';
BEGIN
  FOR job_record IN SELECT * FROM jsonb_array_elements(p_jobs)
  LOOP
    BEGIN
      INSERT INTO public.jobs (
        id, user_id, customer_id, service_type, job_date,
        location, notes, amount_charged,
        status, payment_status, payment_method,
        quoted_price, hardware_brand, hardware_keyway,
        is_deleted, follow_up_sent, follow_up_sent_at,
        sync_status, created_at, updated_at
      ) VALUES (
        (job_record->>'id')::uuid,
        p_user_id,
        (job_record->>'customer_id')::uuid,
        (job_record->>'service_type')::service_type,
        (job_record->>'job_date')::date,
        job_record->>'location',
        job_record->>'notes',
        NULLIF(job_record->>'amount_charged', '')::numeric,
        COALESCE(NULLIF(job_record->>'status', ''), 'in_progress'),
        COALESCE(NULLIF(job_record->>'payment_status', ''), 'unpaid'),
        NULLIF(job_record->>'payment_method', ''),
        NULLIF(job_record->>'quoted_price', '')::numeric,
        NULLIF(job_record->>'hardware_brand', ''),
        NULLIF(job_record->>'hardware_keyway', ''),
        COALESCE((job_record->>'is_deleted')::boolean, false),
        COALESCE((job_record->>'follow_up_sent')::boolean, false),
        NULLIF(job_record->>'follow_up_sent_at', '')::timestamptz,
        'synced',
        COALESCE(NULLIF(job_record->>'created_at', '')::timestamptz, now()),
        now()
      )
      ON CONFLICT (id) DO UPDATE SET
        service_type     = EXCLUDED.service_type,
        location         = EXCLUDED.location,
        notes            = EXCLUDED.notes,
        amount_charged   = EXCLUDED.amount_charged,
        status           = EXCLUDED.status,
        payment_status   = EXCLUDED.payment_status,
        payment_method   = EXCLUDED.payment_method,
        quoted_price     = EXCLUDED.quoted_price,
        hardware_brand   = EXCLUDED.hardware_brand,
        hardware_keyway  = EXCLUDED.hardware_keyway,
        is_deleted       = EXCLUDED.is_deleted,
        follow_up_sent   = EXCLUDED.follow_up_sent,
        follow_up_sent_at = EXCLUDED.follow_up_sent_at,
        sync_status      = 'synced',
        updated_at       = now()
      RETURNING id INTO new_job_id;

      synced_jobs := synced_jobs || jsonb_build_object(
        'local_id',    job_record->>'id',
        'server_id',   new_job_id,
        'sync_status', 'synced'
      );
    EXCEPTION WHEN OTHERS THEN
      failed_jobs := failed_jobs || jsonb_build_object(
        'local_id', job_record->>'id',
        'error',    SQLERRM
      );
    END;
  END LOOP;

  RETURN jsonb_build_object('synced', synced_jobs, 'failed', failed_jobs);
END;
$$;
