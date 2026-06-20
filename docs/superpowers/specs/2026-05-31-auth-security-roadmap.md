# Keystone Auth & Security Roadmap

## Three-Phase Implementation Plan

### Overview

The Keystone authentication system is fully functional (phone → OTP → password → biometric/PIN → onboarding → dashboard) but has three remaining gaps: (1) no automated regression harness around the core auth flow, (2) no Profile Security section for post-onboarding auth management, (3) no off-channel password recovery path. This doc defines the sequencing and architecture for closing all three.

---

## Phase 1: VM Baseline Test Harness

**Goal:** Lock the working auth flow in automated regression tests before modifying any auth-adjacent code.

**Output:** `vm_baseline_test.py` — a Python script that exercises the app via ADB + Flutter driver, verifying:

1. App launch → LandingScreen renders
2. Phone entry → OTP request → OTP verify → session created
3. Password creation + sign-in with password
4. Tab navigation (Dashboard, Jobs, Customers, More)
5. Job creation flow
6. Customer creation flow
7. Sign-out + sign-back-in

Runs against the physical device (Infinix X6532) using `flutter run --no-enable-impeller`. Reports PASS/FAIL per step with ADB logs on failure.

**Success criteria:** All 7 steps pass. Script is repeatable (idempotent — cleans up test data).

---

## Phase 2: Profile Security Section

### State Matrix

| Auth Method | Visual Status | Action | Backend Operation |
|---|---|---|---|
| **Phone Number** | `[Verified]` + formatted number | Read-only | Reads `UserModel.phoneNumber` from Supabase session |
| **Password** | `[Configured]` | `[Change Password]` | Routes to existing `ResetPasswordScreen` (reuses SMS verification) |
| **Biometrics** | `[Active]` / `[Not Enabled]` | `[Toggle Switch]` | Calls `local_auth.authenticate()` → on success, writes `secure_storage.write(key: 'use_biometrics', value: 'true')` |
| **Secure PIN** | `[Configured]` / `[Not Enabled]` | `[Update PIN]` | Opens 6-digit `AlertDialog` pin-pad, validates against old PIN (if exists), overwrites vault value |

### UI Placement

New **SECURITY** section on `ProfileScreen`, positioned between Contact and About sections. Uses same visual language as existing sections (bottom-border rows, 3D icons, gold accent). Each row shows:

- 3D icon (fingerprint, lock, shield, phone)
- Auth method label
- Status badge (green `[Active]` / amber `[Not Enabled]`)
- Trailing action (toggle switch for biometric, chevron for change PIN/password)

### Edge Function Refactor: Shared SMS Utility

Both `send-login-otp/index.ts` and `send-password-reset/index.ts` duplicate the Africa's Talking HTTP call. Extract into `supabase/functions/_shared/sms.ts`:

```typescript
// supabase/functions/_shared/sms.ts
export async function sendSms(phone: string, message: string): Promise<boolean> {
  const apiKey = Deno.env.get("AFRICASTALKING_API_KEY");
  const username = Deno.env.get("AFRICASTALKING_USERNAME");
  if (!apiKey || !username) {
    console.log(`[MOCK SMS] To: ${phone} — ${message}`);
    return false;
  }
  const res = await fetch("https://api.africastalking.com/version1/messaging", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded", ApiKey: apiKey, Accept: "application/json" },
    body: new URLSearchParams({ username, to: phone, message }),
  });
  return res.ok;
}
```

Both edge functions import this shared helper, removing duplication. No behavioral change — same AT credentials from env, same mock fallback.

### Files to Create/Modify

| File | Action | Purpose |
|---|---|---|
| `lib/features/auth/presentation/widgets/profile_security_section.dart` | Create | New widget with 4 rows (phone, password, biometric, PIN) |
| `lib/features/auth/presentation/screens/reset_password_screen.dart` | Verify exists | Already exists — reuse |
| `lib/features/technician_profile/presentation/screens/profile_screen.dart` | Edit | Insert `ProfileSecuritySection` between Contact and About |
| `supabase/functions/_shared/sms.ts` | Create | Shared SMS utility |
| `supabase/functions/send-login-otp/index.ts` | Edit | Use shared SMS helper |
| `supabase/functions/send-password-reset/index.ts` | Edit | Use shared SMS helper |

---

## Phase 3: Email Handshake (Shadow-Email Recovery)

*Deferred until Phase 1 + 2 are complete. Scope defined in prior session — 3-step verification handshake using an off-channel email for password recovery when SMS is unavailable. Will be spec'd in detail when reached.*

---

## Architecture Decisions

1. **Profile Security is a widget, not a separate screen.** Follows existing profile layout pattern (section widgets inside `SingleChildScrollView`). Avoids navigation complexity.
2. **Biometric toggle is device-enrollment, not app-enrollment.** Toggle ON triggers `local_auth.authenticate()` — if the device has no biometrics enrolled, the OS prompts enrollment. The app only stores the preference flag.
3. **PIN change requires old PIN.** Reuses existing `PinService.verifyPin()` before allowing overwrite. Prevents lockout.
4. **No server-side auth method registry.** All auth method state lives in local `FlutterSecureStorage`. The server only knows the phone number and password hash (via Supabase Auth). This is intentional — device-local auth should stay device-local.

---

## Success Criteria

- **Phase 1:** `vm_baseline_test.py` passes 7/7 steps on physical device
- **Phase 2:** Profile Security section displays all 4 rows with correct status. Biometric toggle enables/disables local auth. PIN change replaces vault hash. AT SMS utility extracted and both edge functions import it.
- **Phase 2 integration test:** Enroll biometric at onboarding → skip PIN → open Profile → see "Fingerprint: Active", "PIN: Not Enabled" → tap PIN row → set PIN → status changes to "Configured".
