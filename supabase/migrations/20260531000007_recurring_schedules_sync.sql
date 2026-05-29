-- Recurring schedules: add sync support + FK to service types
ALTER TABLE public.recurring_job_schedules
  ADD COLUMN IF NOT EXISTS sync_status text NOT NULL DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS service_type_id uuid,
  ADD COLUMN IF NOT EXISTS customer_name text;

COMMENT ON COLUMN public.recurring_job_schedules.sync_status IS 'pending | synced | failed | deleted';
COMMENT ON COLUMN public.recurring_job_schedules.service_type_id IS 'FK to service_types.id for rename resilience';
