-- Inventory refinements from external review

-- 1. Link job_parts to inventory items for exact match (not name-based)
ALTER TABLE public.job_parts ADD COLUMN inventory_item_id uuid;

-- 2. Supplier phone for WhatsApp reorder
ALTER TABLE public.inventory_restocks ADD COLUMN supplier_phone text;

-- 3. Low stock snooze (dismiss until date)
ALTER TABLE public.inventory_items ADD COLUMN snooze_low_stock_until timestamptz;
