CREATE TABLE IF NOT EXISTS public.recurring_job_schedules (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  service_type text NOT NULL,
  interval_type text NOT NULL CHECK (interval_type IN ('weekly', 'monthly', 'quarterly', 'yearly')),
  day_of_week integer,
  day_of_month integer,
  next_due_date date NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_recurring_schedules_user ON public.recurring_job_schedules(user_id);

ALTER TABLE public.recurring_job_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own schedules"
  ON public.recurring_job_schedules
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
