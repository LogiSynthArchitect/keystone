-- Server-authoritative service seeding RPC
-- Atomically checks has_seeded_services, inserts defaults, and marks seeded.

CREATE OR REPLACE FUNCTION public.seed_default_service_types(p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  already_seeded boolean;
  now_ts timestamptz := now();
BEGIN
  -- Check if already seeded
  SELECT has_seeded_services INTO already_seeded
  FROM public.user_settings
  WHERE user_id = p_user_id;

  IF already_seeded THEN
    RETURN false;
  END IF;

  -- Insert default services (UUIDs generated server-side)
  INSERT INTO public.service_types (id, user_id, name, is_default, category, icon_name, created_at, updated_at, updated_by)
  VALUES
    (gen_random_uuid(), p_user_id, 'Car Key Replacement',         true, 'Automotive',      'car',        now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Transponder Key Programming', true, 'Automotive',      'car',        now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Car Lockout',                 true, 'Automotive',      'unlock',     now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Trunk/Boot Unlock',           true, 'Automotive',      'unlock',     now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Key Fob Programming',         true, 'Automotive',      'wifi',       now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Ignition Repair',             true, 'Automotive',      'key',        now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Broken Key Extraction',       true, 'Automotive',      'tools',      now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Motorcycle Keys',             true, 'Automotive',      'motorcycle', now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'House Lockout',               true, 'Residential',     'door-open',  now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Lock Installation',           true, 'Residential',     'lock',       now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Lock Rekeying',               true, 'Residential',     'key',        now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Lock Repair',                 true, 'Residential',     'wrench',     now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Key Duplication',             true, 'Residential',     'key',        now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Smart Lock Install',          true, 'Residential',     'mobile-alt', now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Garage Door Locks',           true, 'Residential',     'lock',       now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Padlock Sales/Installation',  true, 'Residential',     'lock',       now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Mailbox Locks',               true, 'Residential',     'envelope',   now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Window Locks',                true, 'Residential',     'lock',       now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Commercial Lockout',          true, 'Commercial',      'building',   now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Master Key Systems',          true, 'Commercial',      'network-wired', now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Panic Bar Installation',      true, 'Commercial',      'door-closed', now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Door Closer Install',         true, 'Commercial',      'tools',      now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Electric Strike Installation',true, 'Commercial',       'bolt',       now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'High-Security Locks',         true, 'Commercial',      'shield-alt', now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'File Cabinet Locks',          true, 'Commercial',      'archive',    now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Storefront Locks',            true, 'Commercial',      'store',      now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'CCTV Installation',           true, 'Security Systems','video',      now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Video Doorbell Installation', true, 'Security Systems','video',      now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Access Control',              true, 'Security Systems','id-card',    now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Burglar Alarms',              true, 'Security Systems','bell',       now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Intercom Systems',            true, 'Security Systems','phone',      now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Electric Gate Motor Repair',  true, 'Security Systems','tools',      now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Electric Fence Installation', true, 'Security Systems','bolt',       now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Rolling Shutter Repair',      true, 'Security Systems','wrench',     now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Key Cutting',                 true, 'Specialty',       'cut',        now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Safe Opening',                true, 'Specialty',       'unlock',     now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Safe Installation',           true, 'Specialty',       'lock',       now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Gate Automation',             true, 'Specialty',       'tools',      now_ts, now_ts, 'mobile'),
    (gen_random_uuid(), p_user_id, 'Eviction Services',           true, 'Specialty',       'gavel',      now_ts, now_ts, 'mobile');
  
  -- Mark as seeded
  INSERT INTO public.user_settings (user_id, has_seeded_services, created_at, updated_at)
  VALUES (p_user_id, true, now_ts, now_ts)
  ON CONFLICT (user_id) DO UPDATE SET
    has_seeded_services = true,
    updated_at = now_ts;

  RETURN true;
END;
$$;
