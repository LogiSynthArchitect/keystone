-- Add cover_image_url to core entities for card cover images
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS cover_image_url text;
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS cover_image_url text;
ALTER TABLE public.inventory_items ADD COLUMN IF NOT EXISTS cover_image_url text;
ALTER TABLE public.knowledge_notes ADD COLUMN IF NOT EXISTS cover_image_url text;
