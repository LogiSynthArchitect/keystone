CREATE TABLE IF NOT EXISTS public.job_templates (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  service_type text NOT NULL,
  notes text,
  services_json jsonb DEFAULT '[]'::jsonb,
  hardware_json jsonb DEFAULT '[]'::jsonb,
  parts_json jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_job_templates_user_id ON public.job_templates(user_id);

ALTER TABLE public.job_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own templates"
  ON public.job_templates
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
