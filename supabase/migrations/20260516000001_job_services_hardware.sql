-- Migration: job_services + job_hardware
-- Multiple services + structured hardware items per job

-- job_services: each line is a service performed (one job can have many)
CREATE TABLE IF NOT EXISTS public.job_services (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id       uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  service_type text NOT NULL,
  quantity     integer NOT NULL DEFAULT 1,
  unit_price   integer,
  domain       text,
  notes        text,
  sort_order   integer NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.job_services ENABLE ROW LEVEL SECURITY;

-- job_hardware: structured hardware items installed per job
CREATE TABLE IF NOT EXISTS public.job_hardware (
  id               uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id           uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  domain           text,
  category         text,
  brand            text,
  model            text,
  key_spec         text,
  material         text,
  finish           text,
  dimensions       text,
  quantity         integer NOT NULL DEFAULT 1,
  unit_sale_price  integer,
  unit_cost_price  integer,
  notes            text,
  sort_order       integer NOT NULL DEFAULT 0,
  created_at       timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.job_hardware ENABLE ROW LEVEL SECURITY;
