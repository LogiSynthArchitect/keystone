-- Migration: add_correction_requests_table
-- Task 2: Implement In-App Job Correction Request

CREATE TABLE IF NOT EXISTS "public"."correction_requests" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "job_id" UUID NOT NULL REFERENCES "public"."jobs"("id") ON DELETE CASCADE,
    "user_id" UUID NOT NULL REFERENCES "public"."users"("auth_id") ON DELETE CASCADE,
    "reason" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    "admin_notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE "public"."correction_requests" ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can create their own correction requests"
ON "public"."correction_requests"
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own correction requests"
ON "public"."correction_requests"
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all correction requests"
ON "public"."correction_requests"
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "Admins can update correction requests"
ON "public"."correction_requests"
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

-- Trigger for updated_at
CREATE OR REPLACE TRIGGER "update_correction_requests_updated_at"
BEFORE UPDATE ON "public"."correction_requests"
FOR EACH ROW
EXECUTE FUNCTION "public"."update_updated_at_column"();
