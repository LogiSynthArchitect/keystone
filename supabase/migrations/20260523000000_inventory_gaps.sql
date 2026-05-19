-- Gaps identified by external inventory review

-- 1. Stock quantity + location + archive + auto-COGS columns on inventory_items
ALTER TABLE public.inventory_items
  ADD COLUMN quantity integer NOT NULL DEFAULT 0,
  ADD COLUMN low_stock_threshold integer,
  ADD COLUMN location text,
  ADD COLUMN is_archived boolean NOT NULL DEFAULT false,
  ADD COLUMN is_auto_cogs boolean NOT NULL DEFAULT false;

-- 2. Purchase/restock history
CREATE TABLE public.inventory_restocks (
  id uuid PRIMARY KEY,
  item_id uuid NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_cost integer NOT NULL CHECK (unit_cost >= 0),
  total_cost integer NOT NULL CHECK (total_cost >= 0),
  vendor text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.inventory_restocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their restocks"
  ON public.inventory_restocks FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 3. Manual stock adjustment audit log
CREATE TABLE public.inventory_stock_adjustments (
  id uuid PRIMARY KEY,
  item_id uuid NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  adjustment_type text NOT NULL CHECK (adjustment_type IN ('manual_add', 'manual_remove', 'restock', 'job_use', 'job_restore', 'correction')),
  quantity_change integer NOT NULL,
  quantity_after integer NOT NULL,
  reason text,
  reference_type text,
  reference_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.inventory_stock_adjustments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their stock adjustments"
  ON public.inventory_stock_adjustments FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
