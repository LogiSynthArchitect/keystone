-- Migration: job_status_timestamps
-- Track when each status transition happened for analytics & service duration

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS quoted_at       timestamptz,
  ADD COLUMN IF NOT EXISTS in_progress_at  timestamptz,
  ADD COLUMN IF NOT EXISTS completed_at    timestamptz,
  ADD COLUMN IF NOT EXISTS invoiced_at     timestamptz;

-- Backfill: set the matching timestamp to updated_at for existing rows
UPDATE public.jobs SET quoted_at      = updated_at WHERE status = 'quoted';
UPDATE public.jobs SET in_progress_at = updated_at WHERE status = 'in_progress';
UPDATE public.jobs SET completed_at   = updated_at WHERE status = 'completed';
UPDATE public.jobs SET invoiced_at    = updated_at WHERE status = 'invoiced';
