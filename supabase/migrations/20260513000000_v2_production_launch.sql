-- ============================================================
-- V2 Production Launch — Apply ALL missing V2 tables/columns
-- Run this in Supabase Dashboard → SQL Editor for production
-- ============================================================

-- STEP 1: V2 columns on jobs
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS status          text,
  ADD COLUMN IF NOT EXISTS payment_status  text,
  ADD COLUMN IF NOT EXISTS payment_method  text,
  ADD COLUMN IF NOT EXISTS quoted_price    numeric(12,2),
  ADD COLUMN IF NOT EXISTS hardware_brand  text,
  ADD COLUMN IF NOT EXISTS hardware_keyway text,
  ADD COLUMN IF NOT EXISTS is_archived     boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS deleted_at      timestamptz;

UPDATE public.jobs SET status = 'in_progress' WHERE status IS NULL;
UPDATE public.jobs SET payment_status = 'unpaid' WHERE payment_status IS NULL;

-- STEP 2: V2 columns on customers
ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS lead_source   text,
  ADD COLUMN IF NOT EXISTS property_type text;

-- STEP 3: V2 columns on follow_ups
ALTER TABLE public.follow_ups
  ADD COLUMN IF NOT EXISTS response_status      text NOT NULL DEFAULT 'sent',
  ADD COLUMN IF NOT EXISTS response_updated_at  timestamptz;

-- STEP 4: service_types table
CREATE TABLE IF NOT EXISTS public.service_types (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name        text NOT NULL,
  is_default  boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.service_types ENABLE ROW LEVEL SECURITY;

-- STEP 5: job_parts table
CREATE TABLE IF NOT EXISTS public.job_parts (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id     uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  part_name  text NOT NULL,
  quantity   integer NOT NULL DEFAULT 1,
  unit_price numeric(12,2),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.job_parts ENABLE ROW LEVEL SECURITY;

-- STEP 6: job_audit_log table
CREATE TABLE IF NOT EXISTS public.job_audit_log (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id     uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES public.users(id),
  action     text NOT NULL,
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.job_audit_log ENABLE ROW LEVEL SECURITY;

-- STEP 7: job_photos table
CREATE TABLE IF NOT EXISTS public.job_photos (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id       uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  label        text,
  created_at   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.job_photos ENABLE ROW LEVEL SECURITY;

-- STEP 8: customer_audit_entries table
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

-- STEP 9: note_job_links table
CREATE TABLE IF NOT EXISTS public.note_job_links (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id    uuid NOT NULL REFERENCES public.knowledge_notes(id) ON DELETE CASCADE,
  job_id     uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT note_job_links_unique UNIQUE (note_id, job_id)
);
ALTER TABLE public.note_job_links ENABLE ROW LEVEL SECURITY;

-- STEP 10: reminders table
CREATE TABLE IF NOT EXISTS public.reminders (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  job_id        uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  type          text NOT NULL,
  status        text NOT NULL DEFAULT 'active',
  snoozed_until timestamptz,
  dismissed_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

-- STEP 11: key_code_history table
CREATE TABLE IF NOT EXISTS public.key_code_history (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id  uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  key_type     text,
  key_code     text,
  bitting      text,
  lock_brand   text,
  notes        text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.key_code_history ENABLE ROW LEVEL SECURITY;

-- STEP 12: activity_events table
CREATE TABLE IF NOT EXISTS public.activity_events (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  event_type  text NOT NULL,
  related_id  uuid,
  description text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;

-- STEP 13: Update users permissions
ALTER TABLE public.users
  ALTER COLUMN permissions
  SET DEFAULT '{"can_delete_jobs": true, "can_view_key_codes": true, "can_edit_final_price": true, "can_manage_service_types": false, "can_view_all_technician_data": false}'::jsonb;

UPDATE public.users
SET permissions = permissions
  || '{"can_manage_service_types": false, "can_view_all_technician_data": false}'::jsonb
WHERE NOT (permissions ? 'can_manage_service_types')
   OR NOT (permissions ? 'can_view_all_technician_data');

-- STEP 14: Add basic RLS policies
-- service_types
DROP POLICY IF EXISTS service_types_select ON public.service_types;
CREATE POLICY service_types_select ON public.service_types FOR SELECT
  TO authenticated USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));
CREATE POLICY service_types_insert ON public.service_types FOR INSERT
  TO authenticated WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));
CREATE POLICY service_types_delete ON public.service_types FOR DELETE
  TO authenticated USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- job_parts
DROP POLICY IF EXISTS job_parts_select ON public.job_parts;
CREATE POLICY job_parts_select ON public.job_parts FOR SELECT
  TO authenticated USING (job_id IN (SELECT id FROM public.jobs WHERE user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())));
CREATE POLICY job_parts_insert ON public.job_parts FOR INSERT
  TO authenticated WITH CHECK (job_id IN (SELECT id FROM public.jobs WHERE user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())));

-- job_audit_log
DROP POLICY IF EXISTS audit_log_select ON public.job_audit_log;
CREATE POLICY audit_log_select ON public.job_audit_log FOR SELECT
  TO authenticated USING (job_id IN (SELECT id FROM public.jobs WHERE user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())));
CREATE POLICY audit_log_insert ON public.job_audit_log FOR INSERT
  TO authenticated WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- job_photos
DROP POLICY IF EXISTS job_photos_select ON public.job_photos;
CREATE POLICY job_photos_select ON public.job_photos FOR SELECT
  TO authenticated USING (job_id IN (SELECT id FROM public.jobs WHERE user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())));
CREATE POLICY job_photos_insert ON public.job_photos FOR INSERT
  TO authenticated WITH CHECK (job_id IN (SELECT id FROM public.jobs WHERE user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())));

-- customer_audit_entries
DROP POLICY IF EXISTS customer_audit_select ON public.customer_audit_entries;
CREATE POLICY customer_audit_select ON public.customer_audit_entries FOR SELECT
  TO authenticated USING (customer_id IN (SELECT id FROM public.customers WHERE user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())));

-- note_job_links
DROP POLICY IF EXISTS note_job_links_select ON public.note_job_links;
CREATE POLICY note_job_links_select ON public.note_job_links FOR SELECT
  TO authenticated USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));
CREATE POLICY note_job_links_insert ON public.note_job_links FOR INSERT
  TO authenticated WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- reminders
DROP POLICY IF EXISTS reminders_select ON public.reminders;
CREATE POLICY reminders_select ON public.reminders FOR SELECT
  TO authenticated USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));
CREATE POLICY reminders_insert ON public.reminders FOR INSERT
  TO authenticated WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));
CREATE POLICY reminders_update ON public.reminders FOR UPDATE
  TO authenticated USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- key_code_history
DROP POLICY IF EXISTS key_codes_select ON public.key_code_history;
CREATE POLICY key_codes_select ON public.key_code_history FOR SELECT
  TO authenticated USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));
CREATE POLICY key_codes_insert ON public.key_code_history FOR INSERT
  TO authenticated WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));
CREATE POLICY key_codes_update ON public.key_code_history FOR UPDATE
  TO authenticated USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));
CREATE POLICY key_codes_delete ON public.key_code_history FOR DELETE
  TO authenticated USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- activity_events
DROP POLICY IF EXISTS activity_events_select ON public.activity_events;
CREATE POLICY activity_events_select ON public.activity_events FOR SELECT
  TO authenticated USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));
CREATE POLICY activity_events_insert ON public.activity_events FOR INSERT
  TO authenticated WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- STEP 15: Create job-photos storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('job-photos', 'job-photos', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "job_photos_storage_insert" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (
    bucket_id = 'job-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "job_photos_storage_select" ON storage.objects
  FOR SELECT TO authenticated USING (
    bucket_id = 'job-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- STEP 16: Indexes for performance
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(user_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_payment_status ON public.jobs(user_id, payment_status);
CREATE INDEX IF NOT EXISTS idx_jobs_not_archived ON public.jobs(user_id) WHERE is_archived = false;
CREATE INDEX IF NOT EXISTS idx_customers_property_type ON public.customers(user_id, property_type) WHERE property_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customers_lead_source ON public.customers(user_id, lead_source) WHERE lead_source IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_job_parts_job ON public.job_parts(job_id);
CREATE INDEX IF NOT EXISTS idx_job_audit_log_job ON public.job_audit_log(job_id);
CREATE INDEX IF NOT EXISTS idx_job_photos_job ON public.job_photos(job_id);
CREATE INDEX IF NOT EXISTS idx_reminders_active ON public.reminders(user_id, status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_key_codes_customer ON public.key_code_history(customer_id);
CREATE INDEX IF NOT EXISTS idx_activity_events_user ON public.activity_events(user_id, created_at DESC);

-- ============================================================
-- V2 MIGRATION COMPLETE
-- ============================================================
