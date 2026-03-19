CREATE OR REPLACE FUNCTION "public"."batch_sync_jobs"("p_user_id" "uuid", "p_jobs" "jsonb")
RETURNS "jsonb" LANGUAGE "plpgsql" SECURITY DEFINER AS $$
DECLARE
  job_record JSONB;
  new_job_id UUID;
  synced_jobs JSONB := '[]';
  failed_jobs JSONB := '[]';
BEGIN
  FOR job_record IN SELECT * FROM jsonb_array_elements(p_jobs)
  LOOP
    BEGIN
      INSERT INTO jobs (id, user_id, customer_id, service_type, job_date, location, notes, amount_charged, sync_status)
      VALUES (
        (job_record->>'id')::UUID,
        p_user_id,
        (job_record->>'customer_id')::UUID,
        (job_record->>'service_type')::service_type,
        (job_record->>'job_date')::DATE,
        job_record->>'location',
        job_record->>'notes',
        (job_record->>'amount_charged')::DECIMAL,
        'synced'
      )
      ON CONFLICT (id) DO UPDATE SET
        sync_status = EXCLUDED.sync_status,
        updated_at = NOW()
      RETURNING id INTO new_job_id;

      -- FIX: was job_record->>'local_id' (always NULL). Now uses 'id' which is what Flutter sends.
      synced_jobs := synced_jobs || jsonb_build_object(
        'local_id', job_record->>'id',
        'server_id', new_job_id,
        'sync_status', 'synced'
      );
    EXCEPTION WHEN OTHERS THEN
      failed_jobs := failed_jobs || jsonb_build_object('local_id', job_record->>'id', 'error', SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object('synced', synced_jobs, 'failed', failed_jobs);
END;
$$;
