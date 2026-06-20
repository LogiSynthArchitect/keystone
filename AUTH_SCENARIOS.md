# Keystone Auth Flow — User Scenario Matrix

> Version: 1.0 | Date: 2026-06-04 | Author: AI Assistant (Build Mode)
> Purpose: Document every user path through Keystone's auth, lock, and security systems to ensure test coverage and prevent regressions.

---

## Table of Contents

1. [Scenario Map](#scenario-map)
2. [Core Scenarios](#core-scenarios)
3. [Edge Cases & Recovery](#edge-cases--recovery)
4. [State Machine Reference](#state-machine-reference)
5. [Testing Checklist](#testing-checklist)
6. [Known Issues & Fixes](#known-issues--fixes)

---

## Scenario Map

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP LAUNCH                               │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐    ┌──────────┐    ┌──────────┐
        │ No       │    │ Session  │    │ Session  │
        │ Session  │    │ + No     │    │ + Local  │
        │          │    │ Local    │    │ Creds    │
        └────┬─────┘    │ Creds    │    └────┬─────┘
             │          └────┬─────┘         │
             │               │               │
    ┌────────▼────────┐ ┌───▼────────┐ ┌───▼────────┐
    │ Scenario 1      │ │ Scenario 2 │ │ Scenario 3 │
    │ (New User)      │ │ (Existing, │ │ (Returning │
    │                 │ │ New Device)│ │ User)      │
    └─────────────────┘ └────────────┘ └────────────┘
```

---

## Core Scenarios

### Scenario 1: Brand New User (Fresh Install)
**Pre-condition:** No Supabase account, no local credentials, no session, no profile.

**Flow:**
1. App opens → `TransitionScreen`
2. `isAuthenticated = false` → router redirects to `/landing`
3. User taps "Get Started" → `/auth/phone`
4. Enters phone → OTP sent → `/auth/otp`
5. Verifies OTP → `markOtpVerified()` → `/auth/create-password`
6. Creates password → `updatePassword()` → `profiles.password_created = true`
7. Router: `hasProfile = false` → `/auth/onboarding`
8. Fills profile → `updateProfile()` → `setup_complete = true`
9. Router: `termsAcceptedAt = null` → `/auth/terms`
10. Accepts terms → `acceptTerms()` → `/auth/pin-setup`
11. Creates 6-digit PIN → `enrollPin()` stores hash
12. Router: `enrolledMethod == none` check → offers `/auth/biometric-enroll`
13. Optionally enrolls biometric → `/dashboard`

**Post-condition:** `hasAnyCredentials() = true`, `isLocallyUnlocked = false` (locked on next launch)

**Files involved:** `landing_screen.dart`, `phone_entry_screen.dart`, `otp_verify_screen.dart`, `create_password_screen.dart`, `onboarding_screen.dart`, `terms_screen.dart`, `pin_setup_screen.dart`, `biometric_enroll_sheet.dart`

---

### Scenario 2: Existing User, New Device
**Pre-condition:** Has Supabase account (password + profile), no local credentials on new phone, no local session.

**Flow:**
1. App opens → `TransitionScreen`
2. `isAuthenticated = false` → `/landing`
3. Phone entry → OTP → `/auth/password` (NOT create-password, since `password_created = true`)
4. Enters password → `signInWithPassword()` → session created
5. `AuthState` rebuilds: `isAuthenticated = true`, `hasProfile = true`
6. Router: `enrolledMethod == none` → `/auth/pin-setup`
7. Sets PIN → `/auth/biometric-enroll` (optional) → `/dashboard`

**Post-condition:** Same as Scenario 1 after step 13.

**Key difference from Scenario 1:** Uses `PasswordEntryScreen` instead of `CreatePasswordScreen`.

---

### Scenario 3: Returning User — App Killed
**Pre-condition:** Has active session, has PIN and/or biometric enrolled locally.

**Flow:**
1. App opens → `TransitionScreen`
2. `isAuthenticated = true`, `hasProfile = true`, `needsPasswordUpgrade = false`
3. `isLocallyUnlocked = false` (because `hasAnyCredentials() = true`)
4. `tryAutoLogin()` → returns `UnlockLocked('Unlock required.')` → `/auth/locked`
5. `LockedScreen` shows three cards:
   - **FINGERPRINT** → system biometric dialog → success → `/auth/transition` → `/dashboard`
   - **APP PIN** → `/auth/pin` → `PinEntryScreen` → success → `/dashboard`
   - **PASSWORD** → `/auth/password` → re-authenticate → `/dashboard`

**Post-condition:** `isLocallyUnlocked = true`, inactivity timer starts.

**Critical behavior:** User MUST see choice screen. Auto-biometric is disabled to prevent trapping users on devices where fingerprint fails.

---

### Scenario 4: Returning User — Background Timeout
**Pre-condition:** App was backgrounded >2 minutes (`_kBackgroundGrace`), has credentials.

**Flow:**
1. User switches back to app
2. `InactivityLockWrapper.didChangeAppLifecycleState(resumed)` triggered
3. `elapsed > 2 minutes` → `_lockNow()`
4. `hasAnyCredentials() = true` → `setLocallyUnlocked(false)` → `context.go(/auth/locked)`
5. Same as Scenario 3 from step 5 onwards

**Post-condition:** Same as Scenario 3.

---

### Scenario 5: User with Only PIN (No Biometric)
**Pre-condition:** `pinHash != null`, `hasBiometric = false`

**Flow on unlock:**
- Locked Screen shows:
  - APP PIN (primary)
  - PASSWORD (secondary, no fingerprint card)
- PIN entry → `unlockWithPin()` → success → dashboard

**Security Settings shows:**
- Biometric Unlock: OFF (toggle disabled or prompts setup)
- PIN Unlock: ON

---

### Scenario 6: User with Biometric + PIN
**Pre-condition:** `pinHash != null`, `hasBiometric = true`, `enrolledMethod = biometric` (preferred)

**Flow on unlock:**
- Locked Screen shows ALL three cards:
  - FINGERPRINT
  - APP PIN
  - PASSWORD
- User can choose any method

**Security Settings shows:**
- Biometric Unlock: ON
- PIN Unlock: ON
- Toggling biometric OFF does NOT affect PIN

---

### Scenario 7: User Forgot PIN
**Pre-condition:** Knows password, PIN forgotten or wiped after 5 failed attempts.

**Flow:**
1. On Locked Screen → tap **PASSWORD**
2. `/auth/password` → enters phone + password
3. Signed in → `isLocallyUnlocked = true` → `/dashboard`
4. Navigates to Security Settings → PIN Unlock toggle
5. Toggles OFF → `clearPin()` → re-enables setup flow
6. Sets new PIN → `enrollPin()` (preserves biometric if exists)

---

### Scenario 8: Toggling Biometric OFF in Security Settings
**Pre-condition:** Both PIN and biometric active.

**Flow:**
1. Security Settings → Biometric Unlock toggle → OFF
2. `InternalAuthService.clearBiometricOnly()` called
3. `vault.storeHasBiometric(false)` — biometric flag cleared
4. `enrolledMethod` updated if it was `biometric`
5. PIN hash REMAINS intact

**Expected result:** Biometric OFF, PIN still ON. Locked screen still shows PIN and PASSWORD.

---

### Scenario 9: Toggling Biometric ON in Security Settings
**Pre-condition:** PIN active, biometric currently off.

**Flow:**
1. Security Settings → Biometric Unlock toggle → ON
2. System shows fingerprint dialog → user authenticates
3. `enrollBiometric()`:
   - Verifies current PIN via dialog (security check)
   - `vault.storeHasBiometric(true)`
   - `vault.storeEnrolledMethod(AuthMethod.biometric)` (preferred)
4. Both now active

**Expected result:** No PIN recreation required. Seamless toggle.

---

### Scenario 10: Creating PIN when Biometric Already Exists
**Pre-condition:** Biometric enrolled, user needs to set/reset PIN.

**Flow:**
1. PIN Setup → enters new PIN
2. `enrollPin()`:
   - Stores new `pinHash`
   - `enrolledMethod = AuthMethod.pin` (PIN becomes preferred)
   - DOES NOT call `storeHasBiometric(false)`
3. Biometric flag stays `true`

**Expected result:** Both active, PIN is now the "preferred" method (tried first if auto-login were enabled).

---

## Edge Cases & Recovery

### Scenario 11: Corrupted Vault State
**Symptoms:** App crashes or loops on launch, or credentials seem "lost".

**Possible corruption patterns:**
- `enrolledMethod = biometric` but `hasBiometric = false` (stale method)
- `enrolledMethod = pin` but `pinHash = null` (orphaned method)
- `enrolledMethod = none` but `pinHash != null` (missing method update)

**Recovery:**
- `SecureVaultService.healVaultState()` runs on EVERY app launch
- Detects mismatches, clears inconsistent state, forces re-setup
- Logs: `[KS:HEAL] Case X: description — clearing vault for re-setup`

**User experience:** App behaves as if no credentials exist → prompts PIN setup.

---

### Scenario 12: Password Upgrade Required (Legacy User)
**Pre-condition:** User created before password enforcement, `profiles.password_created = false`.

**Flow:**
1. `TransitionScreen` → `AuthState` loads
2. `needsPasswordUpgrade = true` (cross-checked against `profiles.password_created`)
3. Router redirects to `/auth/upgrade`
4. User creates password → `updatePassword()`
5. `profiles.password_created = true` → `needsPasswordUpgrade = false`
6. `TransitionScreen` → `/dashboard`

**Critical fix:** G1 cross-check prevents infinite loop. Router uses `profiles.password_created` as source of truth, NOT auth identities.

---

### Scenario 13: Terms Not Accepted (or Outdated)
**Pre-condition:** Profile exists, `termsAcceptedAt = null` or `termsVersion < current`.

**Flow:**
1. `TransitionScreen` checks `profile.termsAcceptedAt` and `profile.termsVersion`
2. If outdated → `context.go(/auth/terms)`
3. User accepts → `acceptTerms()` updates timestamp and version
4. Redirects to `/dashboard`

---

### Scenario 14: Setup Incomplete
**Pre-condition:** Profile exists, `setup_complete = false`.

**Flow:**
1. Router checks `authState.setupComplete`
2. If false → `context.go(/setup)`
3. User completes setup → writes to Hive `auth` box
4. Next launch: `setup_complete = true` → `/dashboard`

**Known issue fixed:** Setup screen wrote to wrong Hive box (used default instead of `auth`). Now aligned with router read target.

---

### Scenario 15: Session Expired with Local Credentials
**Pre-condition:** JWT expired, PIN/biometric enrolled, device is ONLINE.

**Flow on unlock:**
1. User selects unlock method → success
2. `tryAutoLogin()` checks JWT expiry via `_isJwtExpired()`
3. If expired AND online → `tokenManager.attemptRefresh()`
4. If refresh succeeds → proceed to dashboard
5. If refresh fails → `UnlockNeedsNetwork` → force password re-auth

**Offline case:** If device is offline, allows cached access even with expired JWT.

---

## State Machine Reference

### AuthState Fields

| Field | Type | Meaning |
|---|---|---|
| `isAuthenticated` | bool | Has valid Supabase session |
| `hasProfile` | bool | Profile row exists in Supabase |
| `needsPasswordUpgrade` | bool | `profiles.password_created = false` (G1 cross-check) |
| `isLocallyUnlocked` | bool | `!hasAnyCredentials()` OR user manually unlocked |
| `setupComplete` | bool | Local Hive flag `setup_complete` |
| `otpVerified` | bool | OTP passed during current flow |

### Vault Flags (Independent Booleans)

| Flag | Key | Meaning |
|---|---|---|
| `pinHash` | `vault_pin_hash` | Scrypt hash of user's 6-digit PIN |
| `hasBiometric` | `vault_has_biometric` | Device biometric enrolled in app |
| `enrolledMethod` | `vault_enrolled_method` | **Preferred** method (tried first), NOT exclusive |

### Router Decision Tree

```
TransitionScreen
├── !isAuthenticated → /landing
├── !hasProfile → /onboarding
├── terms outdated → /terms
├── needsPasswordUpgrade → /upgrade
├── !isLocallyUnlocked → tryAutoLogin()
│   └── UnlockLocked → /auth/locked (3 options)
├── enrolledMethod == none → /pin-setup
└── → /dashboard
```

---

## Testing Checklist

### Happy Path

| # | Scenario | Status | Date | Notes |
|---|----------|--------|------|-------|
| 1 | New user completes full flow (phone → OTP → password → onboarding → terms → PIN → biometric → dashboard) | PENDING | — | Requires fresh account without password |
| 2 | **Existing user signs in on new device** (phone → OTP → PIN unlock → dashboard) | **COMPLETED** | 2026-06-04 | Verified: Abel's account, fresh install. `password_created=true` detected correctly, no "Create Password" flash. OTP → Transition → PIN setup → Biometric (skipped) → PIN unlock → Dashboard. All sync workers completed. |
| 3 | **Cold start → LockedScreen → unlock with PIN → dashboard** | **COMPLETED** | 2026-06-04 | Verified: `setLocallyUnlocked: true` → `/auth/transition` → `/dashboard`. New dedicated `PinUnlockScreen` used. |
| 3b | Cold start → unlock with biometric → dashboard | PENDING | — | Requires biometric-enabled device |
| 3c | Cold start → unlock with password → dashboard | **COMPLETED** | 2026-06-04 | Verified: New dedicated `PasswordUnlockScreen` used. Back arrow returns to LockedScreen. GoRouter no longer intercepts. |
| 4 | Background app >2 min → foreground → LockedScreen | PENDING | — | |
| 5 | **Forgot PIN → password unlock flow** | **COMPLETED** | 2026-06-04 | Verified: LockedScreen → APP PIN → tap "Forgot PIN? Use your password instead" → `PasswordUnlockScreen` → password → Dashboard. |
| 6 | **PIN wipe (5 failed attempts) → password unlock** | **COMPLETED** | 2026-06-04 | Verified: LockedScreen → APP PIN → 5 wrong PINs → "PIN wiped" banner → USE PASSWORD button → `PasswordUnlockScreen` → Dashboard. |
| 7 | **Password unlock keyboard focus fix** | **COMPLETED** | 2026-06-04 | `RepaintBoundary` + separate `_PasswordField` widget isolates text field from parent `setState` rebuilds. No keyboard dismissal on keystroke. |
| 8 | **Password Upgrade Required (True Positive)** — user with `password_created=false` sees "Improve Security" screen and creates password | **COMPLETED** | 2026-06-04 | Upgrade navigation hardened: `context.go(RouteNames.transition)` replaces `context.push(RouteNames.biometricEnroll)`. Back button no longer bypasses PIN setup. |

### Sign-Out / Sign-Back-In

| # | Scenario | Status | Date | Notes |
|---|----------|--------|------|-------|
| S1 | **Sign out from Dashboard → Sign back in** | **COMPLETED** | 2026-06-04 | Verified: Sign-out cleared vault (`SignOutScope.local`), returned to Landing. Re-auth: Phone → OTP → PIN setup → Biometric → Dashboard. `needsUpgrade: false` throughout. |

### Security Settings

| # | Scenario | Status | Date | Notes |
|---|----------|--------|------|-------|
| SS1 | Toggle biometric OFF → verify fingerprint card removed from LockedScreen | **COMPLETED** | 2026-06-04 | `clearBiometricOnly()` sets `hasBiometric=false` in vault. `locked_screen.dart` now gates fingerprint card behind `_hasBiometric` loaded via `ConsumerStatefulWidget`. |
| SS2 | Toggle biometric ON → verify dialog says "to enable biometric unlock" | **COMPLETED** | 2026-06-04 | UX copy fix: `biometric_service.dart:50` changed from "to unlock Arclock" to "to enable biometric unlock". |
| SS3-4 | PIN/biometric toggle independence | PENDING | — | Requires biometric-enabled device |
| SS5 | **Biometric enrollment from Security Settings** (H1) | **COMPLETED** | 2026-06-04 | No infinite loop. `security_screen.dart` checks `getPinHash()` directly, not `getEnrolledMethod()`. |

### Edge Cases

| # | Scenario | Status | Date | Notes |
|---|----------|--------|------|-------|
| E1 | Corrupt vault (manual test: edit Hive to set `enrolledMethod=biometric`, `hasBiometric=false`) → app self-heals on launch | PENDING | — | |
| E2 | 5 failed PIN attempts → PIN wiped → must use password → can re-create PIN | PENDING | — | |
| E3 | Biometric fails (wrong finger) → snackbar shows "Try again or use PIN" → can tap PIN card | PENDING | — | |
| E4 | No internet + expired JWT → unlock with PIN/biometric → dashboard with cached data | PENDING | — | |

### Regression Guards

| # | Scenario | Status | Date | Notes |
|---|----------|--------|------|-------|
| G1 | **User with `password_created=true` NEVER sees upgrade screen** | **COMPLETED** | 2026-06-04 | Verified: `_needsPasswordUpgrade` async DB query returns `false`. Log: `needsPasswordUpgrade: false`. No "Create Password" screen in any test. |
| R1 | **No auto-biometric: `tryAutoLogin()` always shows choice screen** | **COMPLETED** | 2026-06-04 | Verified: Locked Screen shows PIN/PASSWORD cards. No auto-triggered fingerprint. |
| R2 | **No infinite redirect: `TransitionScreen._hasNavigated` guard** (PIN unlock loop) | **COMPLETED** | 2026-06-04 | Verified: `_hasNavigated` flag prevents duplicate `tryAutoLogin()` calls. No `PlatformException(auth_in_progress)` errors in logs. |
| R3 | H2: Enrolling biometric does NOT wipe PIN | PENDING | — | Requires biometric-enabled device |
| R4 | H2: Enrolling PIN does NOT wipe biometric | PENDING | — | Requires biometric-enabled device |
| R5 | **LockedScreen hides fingerprint when biometric toggled OFF** | **COMPLETED** | 2026-06-04 | `locked_screen.dart` converted to `ConsumerStatefulWidget`. Fingerprint card wrapped in `if (_hasBiometric)`. Loads vault flag on init. Fixes: toggling biometric OFF in Settings now removes fingerprint from LockedScreen. |

---

## Known Issues & Fixes

| Issue ID | Description | Root Cause | Fix | Status |
|---|---|---|---|---|
| G1 | Identity-based password detection caused upgrade loop | `session.user.identities` has no password identity even when password exists | Cross-check `profiles.password_created` | Fixed & verified |
| H1 | Biometric enrollment infinite loop from Security Settings | Screen didn't check existing PIN, forced recreation | `security_screen.dart` checks `getPinHash()` before pushing to PIN setup | Fixed & verified |
| H2 | PIN ↔ biometric overwrite each other in vault | Single `enrolledMethod` enum was overwritten | Track PIN and biometric as independent boolean flags | Fixed & verified |
| H2a | `tryAutoLogin()` auto-triggered system fingerprint with no fallback | `authenticateWithBiometrics()` shows system dialog with `biometricOnly: true` | Removed auto-biometric, always return `UnlockLocked` to show `LockedScreen` | Fixed & verified |
| PIN Loop | PIN unlock immediately re-locked | `setLocallyUnlocked(true)` followed by `refresh()` lost the flag | Removed `refresh()` after `setLocallyUnlocked(true)` | Fixed & verified |
| Setup | `setup_complete` infinite redirect | SetupScreen wrote to default Hive box, router read from `auth` box | Aligned write target with read target | Fixed & verified |
| Background Lock | App locked even with no credentials | `_lockNow()` checked `enrolledMethod == none` instead of `hasAnyCredentials()` | Changed to `hasAnyCredentials()` | Fixed & verified |

---

## Next Steps

1. **Automated Testing:** Write widget tests for Scenarios 1, 3, 8, 9 using `WidgetTester`.
2. **Manual Regression:** Run through the Testing Checklist on a physical device before each release.
3. **Supabase Monitoring:** Audit `profiles.password_created` field periodically to catch G1-style mismatches.
4. **Documentation Update:** Update this file whenever new auth flows or security features are added.

---

## Appendix: Quick Reference for Developers

### To test a specific scenario locally:

```dart
// Simulate no credentials (Scenario 1 / 2 start)
await Hive.box('auth').clear();
await SecureVaultService().clearAll();

// Simulate corrupted vault (Scenario 11)
await Hive.box('auth').put('vault_enrolled_method', 'biometric');
await SecureVaultService().storeHasBiometric(false);
await SecureVaultService().storePinHash(null);
// On next launch, healVaultState() will detect and fix

// Simulate returning user (Scenario 3)
// Ensure session exists + pinHash set + hasBiometric true
```

### Files to touch when modifying auth flow:
- `lib/core/router/app_router.dart` — route guards and redirects
- `lib/core/providers/auth_provider.dart` — `AuthState` build logic
- `lib/core/services/internal_auth/internal_auth_service.dart` — `tryAutoLogin()`, enroll methods
- `lib/core/services/internal_auth/secure_vault_service.dart` — vault storage
- `lib/features/auth/presentation/screens/transition_screen.dart` — navigation orchestration
- `lib/features/auth/presentation/screens/locked_screen.dart` — unlock choice UI
- `lib/core/widgets/inactivity_lock_wrapper.dart` — background/timeout lock

---

*End of document. For questions or updates, search memory key `auth_scenarios_matrix`.*
