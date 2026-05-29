-- ============================================================
-- Optimistic Concurrency Control for Inventory Items Sync
--
-- Problem: SyncOrchestrator PUSH sends all fields via upsert,
-- allowing the mobile sync daemon to overwrite Admin-edited
-- values (name, price, category, etc.) with stale local data.
--
-- Fix: correction_fields TEXT[] column + updated_by TEXT column.
-- Admin web dashboard sets correction_fields for each edited field.
-- Mobile PUSH (upsert) sends all fields — the ON CONFLICT DO UPDATE
-- skips fields listed in correction_fields, preserving admin edits.
--
-- Mobile PULL merge also respects correction_fields on the client
-- side as a second layer of protection.
-- ============================================================

-- 1. Add OCC columns to inventory_items
ALTER TABLE public.inventory_items
  ADD COLUMN IF NOT EXISTS correction_fields TEXT[] DEFAULT '{}'::text[];

ALTER TABLE public.inventory_items
  ADD COLUMN IF NOT EXISTS updated_by TEXT DEFAULT 'mobile';

COMMENT ON COLUMN public.inventory_items.correction_fields IS
  'Field names locked by Admin edit. Mobile upsert skips these fields.';
COMMENT ON COLUMN public.inventory_items.updated_by IS
  'Who last updated this row: mobile or admin. Used for conflict resolution.';

-- 2. Create upsert function with OCC awareness for inventory_items
CREATE OR REPLACE FUNCTION public.upsert_inventory_item(p_item jsonb, p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
  existing_corrections text[];
BEGIN
  -- Get existing correction_fields if row exists
  SELECT i.correction_fields INTO existing_corrections
  FROM public.inventory_items i
  WHERE i.id = (p_item->>'id')::uuid;

  INSERT INTO public.inventory_items (
    id, user_id, item_type, name, attributes,
    brand, model, key_spec, material, finish, dimensions,
    default_cost_price, default_sale_price, quantity,
    low_stock_threshold, location, is_archived, is_auto_cogs,
    snooze_low_stock_until, cover_image_url,
    applied_transaction_ids,
    correction_fields, updated_by,
    created_at, updated_at
  ) VALUES (
    (p_item->>'id')::uuid,
    p_user_id,
    (p_item->>'item_type')::text,
    p_item->>'name',
    (p_item->>'attributes')::jsonb,
    p_item->>'brand',
    p_item->>'model',
    p_item->>'key_spec',
    p_item->>'material',
    p_item->>'finish',
    p_item->>'dimensions',
    NULLIF(p_item->>'default_cost_price', '')::integer,
    NULLIF(p_item->>'default_sale_price', '')::integer,
    COALESCE(NULLIF(p_item->>'quantity', '')::integer, 0),
    NULLIF(p_item->>'low_stock_threshold', '')::integer,
    p_item->>'location',
    COALESCE((p_item->>'is_archived')::boolean, false),
    COALESCE((p_item->>'is_auto_cogs')::boolean, false),
    NULLIF(p_item->>'snooze_low_stock_until', '')::timestamptz,
    p_item->>'cover_image_url',
    COALESCE(
      (SELECT array_agg(e) FROM jsonb_array_elements_text(p_item->'applied_transaction_ids') AS e),
      '{}'::text[]
    ),
    COALESCE((p_item->>'correction_fields')::text[], '{}'::text[]),
    COALESCE(p_item->>'updated_by', 'mobile'),
    COALESCE(NULLIF(p_item->>'created_at', '')::timestamptz, now()),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    name = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['name'])
      THEN EXCLUDED.name ELSE public.inventory_items.name
    END,
    item_type = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['item_type'])
      THEN EXCLUDED.item_type ELSE public.inventory_items.item_type
    END,
    brand = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['brand'])
      THEN EXCLUDED.brand ELSE public.inventory_items.brand
    END,
    model = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['model'])
      THEN EXCLUDED.model ELSE public.inventory_items.model
    END,
    default_cost_price = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['default_cost_price'])
      THEN EXCLUDED.default_cost_price ELSE public.inventory_items.default_cost_price
    END,
    default_sale_price = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['default_sale_price'])
      THEN EXCLUDED.default_sale_price ELSE public.inventory_items.default_sale_price
    END,
    quantity = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['quantity'])
      THEN EXCLUDED.quantity ELSE public.inventory_items.quantity
    END,
    low_stock_threshold = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['low_stock_threshold'])
      THEN EXCLUDED.low_stock_threshold ELSE public.inventory_items.low_stock_threshold
    END,
    location = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['location'])
      THEN EXCLUDED.location ELSE public.inventory_items.location
    END,
    is_archived = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['is_archived'])
      THEN EXCLUDED.is_archived ELSE public.inventory_items.is_archived
    END,
    is_auto_cogs = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['is_auto_cogs'])
      THEN EXCLUDED.is_auto_cogs ELSE public.inventory_items.is_auto_cogs
    END,
    cover_image_url = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['cover_image_url'])
      THEN EXCLUDED.cover_image_url ELSE public.inventory_items.cover_image_url
    END,
    attributes = CASE
      WHEN existing_corrections IS NULL OR NOT (existing_corrections @> ARRAY['attributes'])
      THEN EXCLUDED.attributes ELSE public.inventory_items.attributes
    END,
    -- Clear correction_fields per-field when mobile value matches server value
    correction_fields =
      CASE WHEN EXCLUDED.name IS NOT DISTINCT FROM public.inventory_items.name
        THEN array_remove(COALESCE(existing_corrections, '{}'), 'name')
        ELSE COALESCE(existing_corrections, '{}')
      END
      || CASE WHEN EXCLUDED.item_type IS NOT DISTINCT FROM public.inventory_items.item_type
        THEN array_remove(COALESCE(existing_corrections, '{}'), 'item_type')
        ELSE '{}'::text[]
      END
      || CASE WHEN EXCLUDED.default_cost_price IS NOT DISTINCT FROM public.inventory_items.default_cost_price
        THEN array_remove(COALESCE(existing_corrections, '{}'), 'default_cost_price')
        ELSE '{}'::text[]
      END
      || CASE WHEN EXCLUDED.default_sale_price IS NOT DISTINCT FROM public.inventory_items.default_sale_price
        THEN array_remove(COALESCE(existing_corrections, '{}'), 'default_sale_price')
        ELSE '{}'::text[]
      END
      || CASE WHEN EXCLUDED.location IS NOT DISTINCT FROM public.inventory_items.location
        THEN array_remove(COALESCE(existing_corrections, '{}'), 'location')
        ELSE '{}'::text[]
      END,
    sync_status = 'synced',
    updated_at = now(),
    updated_by = COALESCE(EXCLUDED.updated_by, 'mobile')
  WHERE public.inventory_items.user_id = p_user_id
  RETURNING to_jsonb(public.inventory_items.*) INTO result;

  RETURN result;
END;
$$;

-- 3. Update the fetch endpoint to include new columns
-- (No change needed — the SELECT * already returns all columns)
