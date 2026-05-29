-- Tombstone Protocol: soft-delete for sync-able entities
-- No row is ever physically deleted from the server.

ALTER TABLE public.job_templates
  ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false;

ALTER TABLE public.inventory_items
  ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false;

ALTER TABLE public.service_types
  ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.job_templates.is_deleted IS 'Soft-delete tombstone. Synced to all devices, then hard-deleted from local Hive.';
COMMENT ON COLUMN public.inventory_items.is_deleted IS 'Soft-delete tombstone. Synced to all devices, then hard-deleted from local Hive.';
COMMENT ON COLUMN public.service_types.is_deleted IS 'Soft-delete tombstone. Synced to all devices, then hard-deleted from local Hive.';
