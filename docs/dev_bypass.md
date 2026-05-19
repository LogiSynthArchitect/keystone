# 🔴 TEMPORARY — Dev Bypass (OTP SMS Workaround)

> **⚠️ REMOVE BEFORE PRODUCTION RELEASE**
> This is a developer-only workaround for SMS delivery issues.
> Delete this file, the `dev-bypass` edge function, and all related app code
> before building the production APK.

---

## Why This Exists

The OTP SMS flow is broken due to:

| Issue | Status |
|-------|--------|
| `sms_provider` = `"twilio"` in Supabase Auth config | Cannot be changed to `"hook"` via API (invalid enum). Supabase Dashboard dropdown grayed out. |
| Twilio credentials | Empty/null (account not set up) |
| Africa's Talking balance | Insufficient credits |
| Supabase Auth hook | Configured correctly (`hook_send_sms_enabled: true`, URI points to `send-login-otp`) but `sms_provider=twilio` blocks the hook from being used |

**Root cause:** `sms_provider=twilio` routes OTP through Twilio which has null credentials → SMS fails → user can't log in.

## How to Use the Dev Bypass

1. Open the app → **Phone Entry** screen
2. Tap the **"SIGN IN"** title text **5 times** rapidly
3. A **"DEV BYPASS (TEMP)"** button appears below the title
4. Enter your phone number as normal
5. Tap **"DEV BYPASS (TEMP)"** instead of "CONTINUE"
6. You are logged in immediately (no OTP needed)

## How It Works

```
App (phone_entry_screen)
  └─ taps "SIGN IN" 5x → reveals Dev Bypass button
  └─ taps Dev Bypass
      └─ calls authNotifier.bypassOtp(phone)
          └─ POST /functions/v1/dev-bypass
              ├─ body: { phone, bypass_secret }
              └─ Edge Function (service_role)
                  ├─ Creates/confirms user in auth.users (phone_confirm: true)
                  └─ Generates magic link → returns access_token + refresh_token
          └─ supabase.auth.setSession(access_token, refresh_token)
          └─ Auth state refreshed → user logged in
```

## Security

- **Not exploitable externally** — `bypass_secret` is required and validated server-side
- **Not visible to normal users** — requires 5-tap gesture on title text
- **Service role key not exposed** — only the edge function has it

## Files to Remove Before Production

| File | Reason |
|------|--------|
| `supabase/functions/dev-bypass/` | Edge function with admin auth privileges |
| `lib/features/auth/presentation/screens/phone_entry_screen.dart` (bypass code) | Hidden bypass trigger + button |
| `lib/features/auth/presentation/providers/auth_notifier.dart` (`bypassOtp()` method) | Bypass logic |
| `docs/dev_bypass.md` | This document |
| Doppler `prd_crd` → `DEV_BYPASS_SECRET` | Secret no longer needed |

## Permanent Fix (When SMS Credits Are Available)

1. Top up Africa's Talking SMS credits
2. Go to **Supabase Dashboard** → **Authentication** → **Settings** → **SMS Provider**
3. Change dropdown from **Twilio** to **Hook**
4. Click **Save**
5. Delete the `dev-bypass` edge function
6. Remove bypass code from app
7. Test OTP login flows normally

## Secret

- Stored in **Doppler** project `keystone`, config `prd_crd`
- Key: `DEV_BYPASS_SECRET`
- Also set in **Supabase Edge Function** env vars (via `supabase secrets set`)
