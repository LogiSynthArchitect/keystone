-- RPC for listing active sessions for the current user
-- Used by the Sessions tab on the Account & Security screen
CREATE OR REPLACE FUNCTION get_my_sessions()
RETURNS TABLE (id uuid, device text, last_active timestamptz, is_current bool)
SECURITY DEFINER
LANGUAGE sql AS $$
  SELECT
    id,
    COALESCE(user_agent, 'Unknown device') as device,
    updated_at as last_active,
    id = (NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'session_id')::uuid AS is_current
  FROM auth.sessions
  WHERE user_id = auth.uid();
$$;
