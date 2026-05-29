-- Extend inventory_items with category enum + jsonb attributes for type-specific fields
-- Keeps old columns (brand, model, etc.) for backward compatibility with existing data.
-- New items use the `attributes` jsonb column instead.

-- 1. Create enum for item categories
DO $$ BEGIN
  CREATE TYPE item_category AS ENUM ('key', 'lock', 'automotive', 'electronic', 'safe', 'consumable');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 2. Add attributes jsonb column
ALTER TABLE public.inventory_items
  ADD COLUMN IF NOT EXISTS attributes jsonb NOT NULL DEFAULT '{}'::jsonb;

-- 3. Migrate old item_type values: 'part' → 'consumable', 'hardware' → 'lock'
UPDATE public.inventory_items
  SET item_type = 'consumable' WHERE item_type = 'part';
UPDATE public.inventory_items
  SET item_type = 'lock' WHERE item_type = 'hardware';

-- 4. Drop old check constraint (replaced by enum) — must happen BEFORE type change
ALTER TABLE public.inventory_items
  DROP CONSTRAINT IF EXISTS inventory_items_item_type_check;

-- 5. Change item_type column type from text to item_category enum
ALTER TABLE public.inventory_items
  ALTER COLUMN item_type TYPE item_category USING item_type::item_category,
  ALTER COLUMN item_type SET NOT NULL,
  ALTER COLUMN item_type SET DEFAULT 'consumable'::item_category;

-- 6. Create GIN index for jsonb queries
CREATE INDEX IF NOT EXISTS idx_inventory_items_attributes
  ON public.inventory_items USING GIN (attributes);

-- 7. Update the type index to match new column
DROP INDEX IF EXISTS idx_inventory_items_type;
CREATE INDEX idx_inventory_items_category ON public.inventory_items(item_type);
