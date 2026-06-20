# Mandatory Local Security Enrollment Flow

## Problem

The Quick Unlock dialog has a SKIP button that lets users bypass local PIN/biometric
enrollment. This creates a security loophole: users reach the Dashboard without any
local unlock method, and when the inactivity lock triggers, the lock screen has no
PIN hash to fall back to, leaving the user stuck.

Additionally, a race condition exists where `authStateProvider.build()` takes ~5 seconds
(Supabase session recovery), during which the GoRouter evaluates routing decisions
against stale or loading data, causing UI flashes and unpredictable redirects.

## Design Decision

**Eliminate all SKIP options for local security enrollment.** PIN setup is mandatory
for every user after their first successful authentication (OTP or password), regardless
of user type. Biometric remains optional but PIN is always enforced.

## User Types & Flows

### Type 1: Brand New User (no Supabase password, no profile, no vault)

```
Phone → OTP → CreatePassword → BiometricEnroll → PIN Setup → Onboarding → Dashboard
```

Flow unchanged from current code. `BiometricEnrollPage` already requires PIN
(`_canContinue => _pinEnabled`) and has no skip option. After UNLOCK trigger:

```
App Reopen → Transition → vault has PIN → tryAutoLogin → UnlockLocked → Locked
```

### Type 2: Existing + Fully Setup (has Supabase password, has profile, has vault)

```
Phone → PasswordEntry → verifyPassword → vault has PIN → setLocallyUnlocked → Transition → Dashboard
```

No change. Vault already has credentials.

```
App Reopen → Transition → vault has PIN → tryAutoLogin → UnlockLocked → PinEntry
```

No change. Existing unlock flow.

### Type 3: Existing + No Supabase Password (has profile, vault empty — fresh install)

This is the bug case. Current flow has a SKIP dialog that bypasses setup.

```
Phone → OTP → CreatePassword → Router hasProfile=true → redirect to /transition
  → vault empty → [WAS: SKIP dialog → Dashboard] [NOW: → PIN Setup mandatory]
  → PIN Setup → enrolled → context.pushReplacement(biometricEnroll)
  → BiometricEnrollPage → already set, CONTINUE → Transition → Dashboard
```

On reopen:
```
App Reopen → Transition → vault has PIN → tryAutoLogin → UnlockLocked → PinEntry → Dashboard
```

### Type 4: Existing + Needs Password Upgrade (has profile, password_created=false)

```
Phone → OTP → Router needsPasswordUpgrade → UpgradeAccount
  → upgradeAccount() → biometricEnroll(extra=transition)
  → BiometricEnrollPage → PIN mandatory → CONTINUE → Transition → Dashboard
```

On reopen:
```
App Reopen → Transition → vault has PIN/unlock → Dashboard
```

### Type 5: Vault Wiped (has Supabase password, has profile, vault empty — new device)

```
Phone → PasswordEntry → verifyPassword → vault empty
  → [WAS: FAST UNLOCK dialog with SKIP] → [NOW: PIN Setup mandatory]
  → PIN Setup → push biometricEnroll → CONTINUE → Transition → Dashboard
```

On reopen:
```
App Reopen → Transition → vault has PIN → tryAutoLogin → UnlockLocked → PinEntry → Dashboard
```

## Code Changes

### 1. transition_screen.dart — Remove SKIP dialog, force PIN setup

Replace lines 95-234 (the `isLocallyUnlocked = true` + `AuthMethod.none` dialog block)
with direct PIN setup navigation:

```dart
} else {
    // User is authenticated + has profile + locally unlocked.
    // Check vault: if no credentials, enforce mandatory PIN setup.
    final vault = SecureVaultService();
    final method = await vault.getEnrolledMethod();
    if (method == AuthMethod.none && mounted) {
        if (mounted) context.go(RouteNames.pinSetup);
        return; // ← HARD STOP — no dashboard until PIN is set
    }
    if (mounted) context.go(RouteNames.dashboard);
}
```

### 2. password_entry_screen.dart — Remove SKIP from Fast Unlock dialog

Replace the FAST UNLOCK dialog (lines 63-100) with direct PIN setup:

```dart
Future<void> _promptFastUnlock(InternalAuthService service) async {
    // PIN is mandatory — no SKIP option
    try {
        await service.enrollBiometric();
    } on BiometricAuthException catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.userMessage), ...),
            );
        }
    }
    if (mounted) context.push(RouteNames.pinSetup);
}
```

Also adjust the caller at line 48-53: remove the `if (method == AuthMethod.none)`
guard so that after password verify, the flow always continues to transition:

```dart
// After verifyPassword success:
await ref.read(authStateProvider.notifier).refresh();
if (!mounted) return;
ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
await KsSuccessMoment.show(context, title: 'WELCOME BACK');
if (mounted) context.go(RouteNames.transition);
```

The PIN enforcement moves from `_promptFastUnlock` to the Transition Screen gatekeeper
(same as app reopen flow).

### 3. GoRouter — Already fixed (no changes needed)

The current whitelist at `app_router.dart` lines 135-139 already protects:
```dart
final isLocalSecurityPath = path == RouteNames.biometricEnroll ||
                            path == RouteNames.pinSetup ||
                            path == RouteNames.locked ||
                            path == RouteNames.pinEntry;
if (isLocalSecurityPath) return null;
```

This ensures PIN setup, biometric enroll, and lock screen are never redirected away
from, regardless of auth state. No infinite loops.

## Flaw Fix 1: Type 3 "Ghost Password" Trap

**Location:** `auth_provider.dart` lines 137-141

**Problem:** `password_created` flag on the `profiles` table overrides the actual
Supabase Auth identity check. If `password_created = true` but the user is still
phone-only (no Supabase password), `effectiveNeedsUpgrade` becomes `false` and the
user skips password creation entirely.

```dart
// CURRENT (buggy):
final passwordCreated = profile != null && profile['password_created'] == true;
final effectiveNeedsUpgrade = passwordCreated ? false : needsUpgrade;
```

**Fix:** The Supabase Auth identities array is the source of truth. If the user is
phone-only, they ALWAYS need a password upgrade regardless of the profile flag.
Fire a background correction to fix the stale profile flag.

```dart
// FIXED:
final identities = session.user.identities;
final isPhoneOnly = identities != null && identities.every((id) => id.provider == 'phone');
bool needsUpgrade = isPhoneOnly;

// Self-healing: if the profile says password_created=true but Supabase Auth
// confirms the user is still phone-only, the profile flag is stale. Correct it.
if (isPhoneOnly && profile?['password_created'] == true) {
    needsUpgrade = true;
    // Background correction (fire-and-forget)
    unawaited(supabase.from('profiles').update({
        'password_created': false,
        'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', session.user.id));
}
```

This guarantees Jeremie (Type 3) actually hits the password creation screen.

## Flaw Fix 2: Hardware Back-Button Escape

**Location:** `lib/features/auth/presentation/screens/pin_setup_screen.dart`

**Problem:** When `context.go(RouteNames.pinSetup)` replaces the transition screen,
an Android back button press returns to `/transition` → vault empty → `/auth/pin-setup`
again, creating a jarring redirect loop.

**Fix:** Wrap `PinSetupScreen` in `PopScope(canPop: false)` when `popOnSuccess` is
false (mandatory flow). This prevents the user from leaving without enrolling.

```dart
// In PinSetupScreen.build(), wrap the Scaffold:
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: widget.popOnSuccess,  // Only allow back if NOT mandatory flow
    child: Scaffold(
      backgroundColor: context.ksc.primary900,
      // ... rest of existing build method
    ),
  );
}
```

If `popOnSuccess = true` (accessed from biometricEnrollPage checklist), the normal
pop behavior is allowed. If `popOnSuccess = false` (accessed from transition screen
gatekeeper), the user cannot back out — they must complete enrollment.

The 5-second `authStateProvider.build()` race is mitigated by two mechanisms:

1. **Transition screen `_profileTimedOut` (5s fallback):** If profile provider
   hangs, proceed with gatekeeper after 5 seconds anyway.

2. **PIN setup as hard gate:** Even if the router briefly allows a path through
   stale data, the transition screen's vault check is the final gatekeeper.
   No user reaches dashboard without vault credentials.

## Verification Checklist

- [ ] Type 1 (brand new): OTP → createPassword → biometricEnroll → PIN → onboarding → dashboard
- [ ] Type 3 (existing, no password): OTP → createPassword → PIN forced → biometricEnroll → dashboard
- [ ] Type 5 (vault wiped): passwordEntry → PIN forced → biometricEnroll → dashboard
- [ ] Reopen (any type): vault has method → tryAutoLogin → lock screen → PIN → dashboard
- [ ] Reopen (fresh type): vault has method → tryAutoLogin → locked → PIN → dashboard
- [ ] No SKIP buttons anywhere in local security flow
- [ ] No infinite loops between transition/setup/dashboard
