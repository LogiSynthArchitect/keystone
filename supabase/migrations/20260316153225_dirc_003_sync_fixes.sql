-- Migration: dirc_003_sync_fixes
-- Fixes P2-001 (Sync Data Loss) and P2-002 (Soft Delete Sync Gap)

-- 1. Fix batch_sync_jobs to update all editable fields on conflict
CREATE OR REPLACE FUNCTION "public"."batch_sync_jobs"("p_user_id" "uuid", "p_jobs" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  job_record JSONB;
  new_job_id UUID;
  synced_jobs JSONB := '[]'::jsonb;
  failed_jobs JSONB := '[]'::jsonb;
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
        location = EXCLUDED.location,
        notes = EXCLUDED.notes,
        amount_charged = EXCLUDED.amount_charged,
        sync_status = EXCLUDED.sync_status,
        updated_at = NOW()
      RETURNING id INTO new_job_id;
      
      synced_jobs := synced_jobs || jsonb_build_object('local_id', job_record->>'id', 'server_id', new_job_id, 'sync_status', 'synced');
    EXCEPTION WHEN OTHERS THEN
      failed_jobs := failed_jobs || jsonb_build_object('local_id', job_record->>'id', 'error', SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object('synced', synced_jobs, 'failed', failed_jobs);
END;
$$;

-- 2. Fix batch_sync_customers to support deleted_at for offline soft deletes
CREATE OR REPLACE FUNCTION "public"."batch_sync_customers"("p_user_id" "uuid", "p_customers" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  customer_record JSONB;
  new_customer_id UUID;
  synced_customers JSONB := '[]'::jsonb;
  failed_customers JSONB := '[]'::jsonb;
BEGIN
  FOR customer_record IN SELECT * FROM jsonb_array_elements(p_customers)
  LOOP
    BEGIN
      INSERT INTO customers (id, user_id, full_name, phone_number, location, notes, deleted_at)
      VALUES (
        (customer_record->>'id')::UUID,
        p_user_id,
        customer_record->>'full_name',
        customer_record->>'phone_number',
        customer_record->>'location',
        customer_record->>'notes',
        (customer_record->>'deleted_at')::TIMESTAMPTZ
      )
      ON CONFLICT (user_id, phone_number) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        location = COALESCE(EXCLUDED.location, customers.location),
        notes = COALESCE(EXCLUDED.notes, customers.notes),
        deleted_at = EXCLUDED.deleted_at,
        updated_at = NOW()
      RETURNING id INTO new_customer_id;
      
      synced_customers := synced_customers || jsonb_build_object('local_id', customer_record->>'id', 'server_id', new_customer_id, 'sync_status', 'synced');
    EXCEPTION WHEN OTHERS THEN
      failed_customers := failed_customers || jsonb_build_object('local_id', customer_record->>'id', 'error', SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object('synced', synced_customers, 'failed', failed_customers);
END;
$$;
