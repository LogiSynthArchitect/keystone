ALTER TABLE public.service_types ADD COLUMN default_price integer;

COMMENT ON COLUMN public.service_types.default_price IS 'Default price in pesewas for this service type. Nullable — technician may leave unset.';
