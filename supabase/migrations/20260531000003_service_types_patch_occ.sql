-- Service Pricing: PATCH Semantics + correction_fields OCC
-- Add column-level conflict resolution fields to service_types

ALTER TABLE public.service_types
  ADD COLUMN IF NOT EXISTS correction_fields text[] DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS updated_by text DEFAULT 'mobile';

COMMENT ON COLUMN public.service_types.correction_fields IS 'Array of field names locked by the most recent write. Empty = no locks.';
COMMENT ON COLUMN public.service_types.updated_by IS 'Who last updated the row: ''mobile'' (tech) or ''admin'' (web dashboard).';
