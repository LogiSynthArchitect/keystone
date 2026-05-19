CREATE TABLE IF NOT EXISTS public.job_expenses (
  id uuid PRIMARY KEY,
  job_id uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  category text NOT NULL CHECK (category IN ('transport', 'parking', 'subcontractor', 'supplies', 'other')),
  description text NOT NULL,
  amount integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_job_expenses_job_id ON public.job_expenses(job_id);

ALTER TABLE public.job_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their job expenses"
  ON public.job_expenses
  FOR ALL
  USING (job_id IN (SELECT id FROM public.jobs WHERE user_id = auth.uid()))
  WITH CHECK (job_id IN (SELECT id FROM public.jobs WHERE user_id = auth.uid()));
