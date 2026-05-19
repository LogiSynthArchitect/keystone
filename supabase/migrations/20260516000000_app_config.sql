CREATE TABLE IF NOT EXISTS public.app_config (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  min_app_version text NOT NULL DEFAULT '1.0.0',
  updated_at timestamptz DEFAULT now()
);

INSERT INTO public.app_config (min_app_version)
VALUES ('1.0.0')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "app_config_select_anon" ON public.app_config
  FOR SELECT USING (true);
