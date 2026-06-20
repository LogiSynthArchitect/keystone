# Auth Overhaul — Execution Plan

## Prerequisite: All prior fixes already applied in code

- [x] `_getInternalUserId()` returns auth_id (not internal users.id)
- [x] `currentUserProvider` returns authId as `.id`
- [x] `unlockWithDeviceAuth()` checks `getHasBiometric()`
- [x] `getJobs()` surfaces error when fetch fails + cache empty
- [x] Security screen reads `getHasBiometric()` separately
- [x] Transition screen 5s profile timeout fallback
- [x] GoRouter local security path whitelist
- [x] Dialogs redesigned (Quick Unlock + Fast Unlock custom containers)
- [x] Lock screen redesigned (card-based unlock)

---

## Execution Order (4 changes)

### Change 1 — `lib/core/providers/auth_provider.dart`

**Location:** Lines 137-141, inside `authStateProvider.build()`

**What:** Supabase Auth identities are source of truth, not profile `password_created` flag. If user is phone-only, they ALWAYS need password upgrade. Fire background DB correction for stale profile flag.

**Old code:**
```dart
final passwordCreated = profile != null && profile['password_created'] == true;
final effectiveNeedsUpgrade = passwordCreated ? false : needsUpgrade;
```

**New code:**
```dart
final identities = session.user.identities;
final isPhoneOnly = identities != null && identities.every((id) => id.provider == 'phone');
bool needsUpgrade = isPhoneOnly;
if (isPhoneOnly && profile?['password_created'] == true) {
    needsUpgrade = true;
    unawaited(supabase.from('profiles').update({
        'password_created': false,
    }).eq('user_id', session.user.id));
}
```

**Add import:** `import 'dart:async';` for `unawaited` (check if already present).

---

### Change 2 — `lib/features/auth/presentation/screens/transition_screen.dart`

**Location:** Lines 95-234, the `isLocallyUnlocked = true` + `AuthMethod.none` block

**What:** Remove entire Quick Unlock dialog. Replace with direct mandatory PIN setup navigation. No dialog, no SKIP, no choice.

**Replace this block (lines 95-234):**
```dart
} else {
  // Going to dashboard — check if quick unlock needs setup
  final vault = SecureVaultService();
  final method = await vault.getEnrolledMethod();
  if (method == AuthMethod.none && mounted) {
    // [ENTIRE DIALOG CODE — remove all of it]
    ...
    if (mounted) context.go(RouteNames.dashboard);
  } else {
    if (mounted) context.go(RouteNames.dashboard);
  }
}
```

**With:**
```dart
} else {
  final vault = SecureVaultService();
  final method = await vault.getEnrolledMethod();
  if (method == AuthMethod.none && mounted) {
    if (mounted) context.go(RouteNames.pinSetup);
    return;
  }
  if (mounted) context.go(RouteNames.dashboard);
}
```

---

### Change 3 — `lib/features/auth/presentation/screens/password_entry_screen.dart`

**Location:** Lines 63-118, the entire `_promptFastUnlock` method + caller

**What:** Remove Fast Unlock dialog. Vault check moves to transition gatekeeper. After password verify, always go to transition regardless of vault state.

**Replace `_promptFastUnlock` (lines 63-100) with:**
```dart
Future<void> _promptFastUnlock(InternalAuthService service) async {
  try {
    await service.enrollBiometric();
  } on BiometricAuthException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  if (mounted) context.push(RouteNames.pinSetup);
}
```

**Replace caller logic (lines 47-53) — remove `method == AuthMethod.none` guard:**
```dart
// OLD:
final method = await service.getEnrolledMethod();
if (method == AuthMethod.none) {
  await _promptFastUnlock(service);
  if (!mounted) return;
  await ref.read(authStateProvider.notifier).refresh();
}
if (!mounted) return;
ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
await KsSuccessMoment.show(context, title: 'WELCOME BACK');
if (mounted) context.go(RouteNames.transition);
```

```dart
// NEW:
await ref.read(authStateProvider.notifier).refresh();
if (!mounted) return;
ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
await KsSuccessMoment.show(context, title: 'WELCOME BACK');
if (mounted) context.go(RouteNames.transition);
```

---

### Change 4 — `lib/features/auth/presentation/screens/pin_setup_screen.dart`

**Location:** `build()` method, wrap Scaffold

**What:** Prevent Android back button from escaping mandatory PIN setup. Use PopScope.

```dart
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: widget.popOnSuccess,
    child: Scaffold(
      backgroundColor: context.ksc.primary900,
      // ... existing build method content
    ),
  );
}
```

This is a wrapper change — the entire existing `Scaffold(...)` becomes the `child` of `PopScope(canPop: widget.popOnSuccess, child: ...)`.

---

## Verification After Changes

- [ ] `dart analyze` passes on all 4 files
- [ ] `scripts/build_apk.sh` builds successfully
- [ ] No SKIP buttons in Quick Unlock or Fast Unlock dialogs (dialogs removed)
- [ ] All 5 user types reach dashboard only via mandatory PIN path
