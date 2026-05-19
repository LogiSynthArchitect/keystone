-- Fix missing CASCADE on inventory tables and add missing follow_ups FKs

-- 1. inventory_restocks.user_id → auth.users(id) with CASCADE
ALTER TABLE public.inventory_restocks
  DROP CONSTRAINT inventory_restocks_user_id_fkey,
  ADD CONSTRAINT inventory_restocks_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 2. inventory_stock_adjustments.user_id → auth.users(id) with CASCADE
ALTER TABLE public.inventory_stock_adjustments
  DROP CONSTRAINT inventory_stock_adjustments_user_id_fkey,
  ADD CONSTRAINT inventory_stock_adjustments_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 3. follow_ups.customer_id → public.customers(id) with CASCADE (missing FK entirely)
ALTER TABLE public.follow_ups
  ADD CONSTRAINT follow_ups_customer_id_fkey
    FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;

-- 4. follow_ups.user_id → auth.users(id) with CASCADE (missing FK entirely)
ALTER TABLE public.follow_ups
  ADD CONSTRAINT follow_ups_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 5. follow_ups.job_id → public.jobs(id) with CASCADE (had UNIQUE but no FK)
ALTER TABLE public.follow_ups
  DROP CONSTRAINT follow_ups_job_id_key,
  ADD CONSTRAINT follow_ups_job_id_fkey
    FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE,
  ADD CONSTRAINT follow_ups_job_id_unique UNIQUE (job_id);
