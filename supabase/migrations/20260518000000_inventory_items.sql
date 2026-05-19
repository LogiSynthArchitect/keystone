CREATE TABLE IF NOT EXISTS public.inventory_items (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_type text NOT NULL CHECK (item_type IN ('part', 'hardware')),
  name text NOT NULL,
  category text,
  brand text,
  model text,
  key_spec text,
  material text,
  finish text,
  dimensions text,
  default_cost_price integer,
  default_sale_price integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_inventory_items_user_id ON public.inventory_items(user_id);
CREATE INDEX idx_inventory_items_type ON public.inventory_items(item_type);

ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own inventory"
  ON public.inventory_items
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
