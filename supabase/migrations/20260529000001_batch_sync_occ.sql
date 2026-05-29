-- ============================================================
-- Optimistic Concurrency Control for batch_sync_jobs
-- 
-- Problem: batch_sync_jobs ON CONFLICT blindly replays all
-- business fields, allowing the mobile sync daemon to overwrite
-- Admin-approved correction values (service_type, location, etc.)
-- with stale mobile data when the device reconnects offline edits.
--
-- Fix: correction_fields TEXT[] column + conditional UPDATE SET
-- that skips fields listed in correction_fields. The array is
-- populated by approve_correction_request and cleared field-by-field
-- by batch_sync_jobs when the mobile's value matches the server's
-- (array_remove for that specific field).
-- ============================================================

-- 1. Add correction_fields column
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS correction_fields TEXT[] DEFAULT '{}'::text[];

COMMENT ON COLUMN public.jobs.correction_fields IS
  'Field names locked by Admin correction. batch_sync_jobs skips these fields. Cleared per-field when mobile value matches server value.';

-- 2. Update approve_correction_request to set correction locks
CREATE OR REPLACE FUNCTION public.approve_correction_request(
  p_request_id  uuid,
  p_job_id      uuid,
  p_updates     jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  corrected_fields TEXT[];
BEGIN
  -- Verify caller is an admin
  IF NOT EXISTS (
    SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  -- Verify p_job_id matches the job linked to this correction request
  IF NOT EXISTS (
    SELECT 1 FROM correction_requests WHERE id = p_request_id AND job_id = p_job_id
  ) THEN
    RAISE EXCEPTION 'Integrity error: p_job_id does not match correction_requests.job_id for request %', p_request_id;
  END IF;

  -- Build the list of corrected field names from p_updates keys
  SELECT array_agg(key) INTO corrected_fields
  FROM jsonb_object_keys(p_updates) AS key;

  -- Update the job fields and set correction locks
  UPDATE jobs SET
    service_type     = COALESCE((p_updates->>'service_type')::service_type, service_type),
    location         = COALESCE(p_updates->>'location',         location),
    notes            = COALESCE(p_updates->>'notes',            notes),
    amount_charged   = COALESCE((p_updates->>'amount_charged')::numeric, amount_charged),
    correction_fields = array_cat(COALESCE(correction_fields, '{}'), corrected_fields),
    updated_at       = now()
  WHERE id = p_job_id;

  -- Mark the request approved
  UPDATE correction_requests
  SET status = 'approved', updated_at = now()
  WHERE id = p_request_id;
END;
$$;

-- 3. Update batch_sync_jobs with field-level conditional updates
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
        -- Each field checks correction_fields: skip if admin-locked
        service_type = CASE
          WHEN j.correction_fields IS NULL
            OR NOT (j.correction_fields @> ARRAY['service_type'])
          THEN EXCLUDED.service_type
          ELSE j.service_type
        END,
        location = CASE
          WHEN j.correction_fields IS NULL
            OR NOT (j.correction_fields @> ARRAY['location'])
          THEN EXCLUDED.location
          ELSE j.location
        END,
        notes = CASE
          WHEN j.correction_fields IS NULL
            OR NOT (j.correction_fields @> ARRAY['notes'])
          THEN EXCLUDED.notes
          ELSE j.notes
        END,
        amount_charged = CASE
          WHEN j.correction_fields IS NULL
            OR NOT (j.correction_fields @> ARRAY['amount_charged'])
          THEN EXCLUDED.amount_charged
          ELSE j.amount_charged
        END,
        status = CASE
          WHEN j.correction_fields IS NULL
            OR NOT (j.correction_fields @> ARRAY['status'])
          THEN EXCLUDED.status
          ELSE j.status
        END,
        payment_status = CASE
          WHEN j.correction_fields IS NULL
            OR NOT (j.correction_fields @> ARRAY['payment_status'])
          THEN EXCLUDED.payment_status
          ELSE j.payment_status
        END,
        -- correction_fields: auto-clear per-field when mobile value matches server
        correction_fields =
          -- Remove 'service_type' from lock array if mobile value matches
          CASE WHEN EXCLUDED.service_type IS NOT DISTINCT FROM j.service_type
            THEN array_remove(COALESCE(j.correction_fields, '{}'), 'service_type')
            ELSE COALESCE(j.correction_fields, '{}')
          END
          --
          || -- concatenate with array_remove results for other fields
          CASE WHEN EXCLUDED.location IS NOT DISTINCT FROM j.location
            THEN array_remove(COALESCE(j.correction_fields, '{}'), 'location')
            ELSE '{}'::text[]
          END
          --
          || CASE WHEN EXCLUDED.notes IS NOT DISTINCT FROM j.notes
            THEN array_remove(COALESCE(j.correction_fields, '{}'), 'notes')
            ELSE '{}'::text[]
          END
          --
          || CASE WHEN EXCLUDED.amount_charged IS NOT DISTINCT FROM j.amount_charged
            THEN array_remove(COALESCE(j.correction_fields, '{}'), 'amount_charged')
            ELSE '{}'::text[]
          END
          --
          || CASE WHEN EXCLUDED.status IS NOT DISTINCT FROM j.status
            THEN array_remove(COALESCE(j.correction_fields, '{}'), 'status')
            ELSE '{}'::text[]
          END
          --
          || CASE WHEN EXCLUDED.payment_status IS NOT DISTINCT FROM j.payment_status
            THEN array_remove(COALESCE(j.correction_fields, '{}'), 'payment_status')
            ELSE '{}'::text[]
          END,
        sync_status = 'synced',
        updated_at  = now()
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

-- 4. Update direct updateJob endpoint (called by editJob when online)
-- to clear only the fields the user actually edited, not the entire array.
-- This preserves concurrent isolation: if Admin locked location+notes and
-- the tech only edited notes, the location lock remains.
--
-- Note: This is handled in the application layer via updateJob(). The
-- Flutter client sends the changed field names, and the server clears
-- only those specific fields from correction_fields:
--
--   UPDATE jobs SET ..., correction_fields = array_remove(correction_fields, 'notes')
--   WHERE id = p_job_id AND p_edited_fields @> ARRAY['notes'];
--
-- Application-layer migration will be added in a follow-up.
