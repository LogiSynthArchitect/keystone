-- ============================================================
-- V2 Security Fixes — Wave 3 — 2026-03-30
-- Applied to DEV on: 2026-03-31
-- Apply to PRODUCTION before launch
-- ============================================================
-- Fixes:
--   FIX 15: Atomic correction request approval via RPC
--   FIX 24: RPC validates job ownership before applying changes
--   FIX 28: batch_sync_jobs ON CONFLICT now replays all business fields
-- ============================================================


-- ------------------------------------------------------------
-- FIX 15 + FIX 24: approve_correction_request
-- Single atomic transaction: validates admin role, validates
-- that p_job_id matches the correction request's job_id,
-- updates the job, then marks the request approved.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION approve_correction_request(
  p_request_id  uuid,
  p_job_id      uuid,
  p_updates     jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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

  -- Update the job fields
  UPDATE jobs SET
    service_type   = COALESCE((p_updates->>'service_type')::service_type, service_type),
    location       = COALESCE(p_updates->>'location',       location),
    notes          = COALESCE(p_updates->>'notes',          notes),
    amount_charged = COALESCE((p_updates->>'amount_charged')::numeric, amount_charged),
    updated_at     = now()
  WHERE id = p_job_id;

  -- Mark the request approved
  UPDATE correction_requests
  SET status = 'approved', updated_at = now()
  WHERE id = p_request_id;
END;
$$;


-- ------------------------------------------------------------
-- FIX 28: batch_sync_jobs — ON CONFLICT replays all business fields
-- Original ON CONFLICT only updated sync_status + updated_at.
-- Jobs edited offline and retried via syncPendingJobs() would sync
-- the row but silently lose field changes (status, amount, etc.)
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.batch_sync_jobs(p_user_id uuid, p_jobs jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  job_record jsonb;
  new_job_id uuid;
  synced_jobs jsonb := '[]';
  failed_jobs jsonb := '[]';
BEGIN
  FOR job_record IN SELECT * FROM jsonb_array_elements(p_jobs)
  LOOP
    BEGIN
      INSERT INTO jobs (id, user_id, customer_id, service_type, job_date, location, notes,
                        amount_charged, status, payment_status, is_deleted, sync_status)
      VALUES (
        (job_record->>'id')::uuid,
        p_user_id,
        (job_record->>'customer_id')::uuid,
        (job_record->>'service_type')::service_type,
        (job_record->>'job_date')::date,
        job_record->>'location',
        job_record->>'notes',
        (job_record->>'amount_charged')::numeric,
        COALESCE(job_record->>'status', 'in_progress'),
        COALESCE(job_record->>'payment_status', 'unpaid'),
        COALESCE((job_record->>'is_deleted')::boolean, false),
        'synced'
      )
      ON CONFLICT (id) DO UPDATE SET
        service_type   = EXCLUDED.service_type,
        location       = EXCLUDED.location,
        notes          = EXCLUDED.notes,
        amount_charged = EXCLUDED.amount_charged,
        status         = EXCLUDED.status,
        payment_status = EXCLUDED.payment_status,
        is_deleted     = EXCLUDED.is_deleted,
        sync_status    = 'synced',
        updated_at     = now()
      RETURNING id INTO new_job_id;

      synced_jobs := synced_jobs || jsonb_build_object(
        'local_id', job_record->>'local_id',
        'server_id', new_job_id,
        'sync_status', 'synced'
      );
    EXCEPTION WHEN OTHERS THEN
      failed_jobs := failed_jobs || jsonb_build_object(
        'local_id', job_record->>'local_id',
        'error', SQLERRM
      );
    END;
  END LOOP;
  RETURN jsonb_build_object('synced', synced_jobs, 'failed', failed_jobs);
END;
$$;
