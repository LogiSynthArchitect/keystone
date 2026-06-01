# Account & Security System — Design Spec

**Date:** 2026-06-01
**Status:** Approved for implementation
**Project:** Keystone

## Problem

The Keystone app has no dedicated security or account management UI. Users cannot change their password, update their phone number, manage active sessions, or delete their account from within the app. The only sign-out button gives no warning about offline data loss. Dead code (`bypassOtp`) and an exposed Supabase PAT (`KS_MGMT_API_KEY`) in an edge function are technical security risks.

## Scope

Build a dedicated **Account & Security screen** at route `/profile/security` with three tabs:

1. **Security tab** — Password change, biometric/PIN management, account deletion
2. **Account tab** — Phone number change, account info, data export
3. **Sessions tab** — List active sessions, revoke others

Also: remove dead `bypassOtp()` code, replace PAT with service role key in edge function.

---

## 1. Route & Navigation

- **Route:** `/profile/security` — child of `/profile`, lazy-loaded, auth-guarded
- **Entry points:**
  - Hub screen: new **Account** section between Tools and Settings → tap "Security & Account"
  - Profile screen: inline link
- **Exit:** AppBar back arrow → return to previous screen (Hub or Profile)

---

## 2. Tab Structure

### Tab A: Security

| Row | Action | UX | Implementation |
|-----|--------|----|----------------|
| 1 | **Change Password** | Tap → bottom sheet with 2 steps: (1) current password (2) new + confirm | `supabase.auth.updateUser(password:)` after re-auth |
| 2 | **Biometric Unlock** | Toggle on/off. On → enroll via `local_auth`. Off → confirm via PIN → clear vault | `InternalAuthService.enrollBiometric()` / `clearBiometric()` |
| 3 | **Change PIN** | Tap → current PIN → new 6-digit → confirm | `InternalAuthService.changePin(oldPin, newPin)` — local vault only |
| 4 | **Delete Account** (Danger Zone) | Tap → 3-step confirmation: warning dialog → phone verification → final execution | Edge function `delete-account` calls `supabaseAdmin.auth.admin.deleteUser()` |

### Tab B: Account

| Row | Action | UX | Implementation |
|-----|--------|----|----------------|
| 1 | **Phone Number** | Tap → new phone input → OTP to new number → verify → update | `supabase.auth.updateUser(phone:)` |
| 2 | **Account Created** | Read-only date from `profiles.created_at` | From `authStateProvider` |
| 3 | **Export My Data** | Downloads all user data as JSON file | Existing export logic, moved from Hub |

### Tab C: Sessions

| Row | Action | UX | Implementation |
|-----|--------|----|----------------|
| 1 | **This Device** (current) | Green highlight, device model + "Last active: now" | From `supabase.auth.getSession()` |
| 2 | **Other sessions** | Listed with device + last active. "Revoke" per row | RPC `get_my_sessions()` queries `auth.sessions` |
| 3 | **Sign out of all others** | Confirm dialog → revoke all non-current | `supabase.auth.signOut(scope: SignOutScope.others)` |

---

## 3. Backend Details

### 3a. Session listing RPC

Postgres function to safely return current user's sessions:

```sql
CREATE OR REPLACE FUNCTION get_my_sessions()
RETURNS TABLE (id uuid, device text, last_active timestamptz, is_current bool)
SECURITY DEFINER
LANGUAGE sql AS $$
  SELECT
    id,
    raw_user_meta_data->>'device' as device,
    updated_at as last_active,
    id = (NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'session_id')::uuid AS is_current
  FROM auth.sessions
  WHERE user_id = auth.uid();
$$;
```

### 3b. Account deletion flow

1. User confirms → Flutter calls new edge function `delete-account`
2. Edge function uses `SUPABASE_SERVICE_ROLE_KEY` to call `supabaseAdmin.auth.admin.deleteUser(userId)`
3. `ON DELETE CASCADE` on `profiles`, `customers`, `jobs`, etc. automatically wipes user data
4. Edge function returns success
5. Flutter calls `signOut()` + `HiveService.clearAll()`
6. Navigate to landing screen

### 3c. Edge function security fix

Replace `KS_MGMT_API_KEY` (PAT) with `SUPABASE_SERVICE_ROLE_KEY` in `send-login-otp`:

- Service role key can write to the `auth.sms_otps` table directly instead of calling Management API
- The edge function already has `SUPABASE_SERVICE_ROLE_KEY` in its environment automatically
- Management API PAT is only needed for project configuration changes, not runtime auth operations

---

## 4. Files

### New files

| File | Purpose |
|------|---------|
| `lib/features/auth/presentation/screens/security_screen.dart` | Tabbed Account & Security screen (3 tabs) |
| `lib/features/auth/presentation/screens/change_password_sheet.dart` | Bottom sheet: current password → new password |
| `lib/features/auth/presentation/screens/delete_account_screen.dart` | Multi-step account deletion flow |
| `lib/features/auth/presentation/screens/change_phone_screen.dart` | Phone number change with OTP verification |
| `supabase/functions/delete-account/index.ts` | Edge function for account deletion |
| `supabase/migrations/20260601_get_my_sessions.sql` | RPC to list user sessions |

### Modified files

| File | Change |
|------|--------|
| `lib/features/auth/presentation/providers/auth_notifier.dart` | Add `changePassword()`, `deleteAccount()`, `changePhone()`. Remove `bypassOtp()` |
| `lib/features/hub/presentation/screens/hub_screen.dart` | Add "Account" section with link to `/profile/security` |
| `lib/core/router/app_router.dart` | Add `/profile/security` route |
| `supabase/functions/send-login-otp/index.ts` | Replace PAT with service role key for SMS OTP operations |

---

## 5. Dead Code Removal

- `AuthNotifier.bypassOtp()` — entirely remove. Was gated behind `kDevMode`, references deleted `dev-bypass` edge function. Any dev bypass needs should use the real OTP flow with test OTP.
- `lib/core/config/dev_mode.dart` — keep the flag, it's still used in other places.

---

## 6. Error Handling

- **Change password**: Show `AuthException` messages inline (weak password, wrong current password)
- **Delete account**: Show loading state, handle network failures gracefully, confirm no partial deletion
- **Change phone**: Handle OTP sending failures, show if number already in use
- **Sessions**: If `get_my_sessions()` RPC fails (permissions), show "Not available" instead of error
- **All security actions**: Require re-authentication (current password or phone verification) for sensitive operations

## 7. Out of Scope (v1)

- Email auth (not used in this app)
- Two-factor authentication (TOTP)
- WebAuthn / passkeys
- Account merging
