-- Migration: Phone Status RPC + password_created flag
-- Supports smart CONTINUE button: single-trip auth strategy detection

-- Add password_created flag to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS password_created BOOLEAN DEFAULT false;

-- Consolidated auth strategy RPC
-- Single Supabase call returns NEW_USER, OTP_USER, or PASSWORD_USER
-- No dummy sign-in attempt, no PII (user id / email / phone) exposed
CREATE OR REPLACE FUNCTION public.get_auth_strategy(p_phone text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $func$
DECLARE
  v_clean_phone text;
  v_user_id uuid;
  v_has_password boolean;
BEGIN
  v_clean_phone := regexp_replace(p_phone, '^\+', '');
  SELECT id INTO v_user_id FROM auth.users WHERE phone = v_clean_phone;

  IF v_user_id IS NULL THEN
    RETURN 'NEW_USER';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM auth.identities
    WHERE user_id = v_user_id AND provider = 'password'
  ) INTO v_has_password;

  IF v_has_password THEN
    RETURN 'PASSWORD_USER';
  ELSE
    RETURN 'OTP_USER';
  END IF;
END;
$func$;

-- Keep old check_phone_status RPC for backward compatibility
