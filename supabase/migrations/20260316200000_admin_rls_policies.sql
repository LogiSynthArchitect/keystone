-- Migration: admin_rls_policies
-- Purpose: Grant admins SELECT and UPDATE access to core tables for the Admin Dashboard.

-- Policies for Jobs
CREATE POLICY "Admins can view all jobs"
ON "public"."jobs"
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "Admins can update all jobs"
ON "public"."jobs"
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = 'admin'
    )
);

-- Policies for Customers
CREATE POLICY "Admins can view all customers"
ON "public"."customers"
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "Admins can update all customers"
ON "public"."customers"
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = 'admin'
    )
);
