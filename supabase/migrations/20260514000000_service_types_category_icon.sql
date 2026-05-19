-- STEP 1: Add category and icon_name columns
ALTER TABLE public.service_types
  ADD COLUMN IF NOT EXISTS category  text DEFAULT 'General';

ALTER TABLE public.service_types
  ADD COLUMN IF NOT EXISTS icon_name text DEFAULT 'tools';

-- STEP 2: Fix the 4 old seed rows with proper categories and icons
UPDATE public.service_types
SET category = 'Automotive',
    icon_name = 'car',
    updated_at = now()
WHERE name = 'Car Key Replacement' AND is_default = true;

UPDATE public.service_types
SET category = 'Residential',
    icon_name = 'door-open',
    updated_at = now()
WHERE name = 'House Lockout' AND is_default = true;

UPDATE public.service_types
SET category = 'Commercial',
    icon_name = 'building',
    updated_at = now()
WHERE name = 'Commercial Lockout' AND is_default = true;

UPDATE public.service_types
SET category = 'Specialty',
    icon_name = 'unlock',
    updated_at = now()
WHERE name = 'Safe Opening' AND is_default = true;

-- STEP 3: Insert all 39 default services for existing users who don't have them yet
-- Only inserts rows where that user doesn't already have a service with the same name
INSERT INTO public.service_types (id, user_id, name, category, icon_name, is_default, created_at, updated_at)
SELECT
  gen_random_uuid(),
  u.id,
  v.name,
  v.category,
  v.icon_name,
  true,
  now(),
  now()
FROM public.users u
CROSS JOIN (VALUES
  -- AUTOMOTIVE
  ('Car Key Replacement',        'Automotive', 'car'),
  ('Transponder Key Programming','Automotive', 'car'),
  ('Car Lockout',                'Automotive', 'unlock'),
  ('Trunk/Boot Unlock',          'Automotive', 'unlock'),
  ('Key Fob Programming',        'Automotive', 'wifi'),
  ('Ignition Repair',            'Automotive', 'key'),
  ('Broken Key Extraction',      'Automotive', 'tools'),
  ('Motorcycle Keys',            'Automotive', 'motorcycle'),
  -- RESIDENTIAL
  ('House Lockout',              'Residential', 'door-open'),
  ('Lock Installation',          'Residential', 'lock'),
  ('Lock Rekeying',              'Residential', 'key'),
  ('Lock Repair',                'Residential', 'wrench'),
  ('Key Duplication',            'Residential', 'key'),
  ('Smart Lock Install',         'Residential', 'mobile-alt'),
  ('Garage Door Locks',          'Residential', 'lock'),
  ('Padlock Sales/Installation', 'Residential', 'lock'),
  ('Mailbox Locks',              'Residential', 'envelope'),
  ('Window Locks',               'Residential', 'lock'),
  -- COMMERCIAL
  ('Commercial Lockout',         'Commercial', 'building'),
  ('Master Key Systems',         'Commercial', 'network-wired'),
  ('Panic Bar Installation',     'Commercial', 'door-closed'),
  ('Door Closer Install',        'Commercial', 'tools'),
  ('Electric Strike Installation','Commercial', 'bolt'),
  ('High-Security Locks',        'Commercial', 'shield-alt'),
  ('File Cabinet Locks',         'Commercial', 'archive'),
  ('Storefront Locks',           'Commercial', 'store'),
  -- SECURITY SYSTEMS
  ('CCTV Installation',          'Security Systems', 'video'),
  ('Video Doorbell Installation','Security Systems', 'video'),
  ('Access Control',             'Security Systems', 'id-card'),
  ('Burglar Alarms',             'Security Systems', 'bell'),
  ('Intercom Systems',           'Security Systems', 'phone'),
  ('Electric Gate Motor Repair', 'Security Systems', 'tools'),
  ('Electric Fence Installation','Security Systems', 'bolt'),
  ('Rolling Shutter Repair',     'Security Systems', 'wrench'),
  -- SPECIALTY
  ('Key Cutting',                'Specialty', 'cut'),
  ('Safe Opening',               'Specialty', 'unlock'),
  ('Safe Installation',          'Specialty', 'lock'),
  ('Gate Automation',            'Specialty', 'tools'),
  ('Eviction Services',          'Specialty', 'gavel')
) AS v(name, category, icon_name)
WHERE NOT EXISTS (
  SELECT 1 FROM public.service_types s
  WHERE s.user_id = u.id AND s.name = v.name
);
