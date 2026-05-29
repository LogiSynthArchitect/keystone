-- Service Pricing: Server-Authoritative Seeding (Kill Zombie Duplicates)
-- Add has_seeded_services as single source of truth.

CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  has_seeded_services boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Users can read/write their own settings
CREATE POLICY "Users manage their own settings"
  ON public.user_settings
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Safe getter RPC — returns false if no row exists (new user)
CREATE OR REPLACE FUNCTION public.get_has_seeded_services(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result boolean;
BEGIN
  SELECT has_seeded_services INTO result
  FROM public.user_settings
  WHERE user_id = target_user_id;
  RETURN COALESCE(result, false);
END;
$$;

-- Atomic mark-as-seeded (insert or update)
CREATE OR REPLACE FUNCTION public.mark_services_seeded(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_settings (user_id, has_seeded_services, created_at, updated_at)
  VALUES (target_user_id, true, now(), now())
  ON CONFLICT (user_id) DO UPDATE SET
    has_seeded_services = true,
    updated_at = now();
END;
$$;
