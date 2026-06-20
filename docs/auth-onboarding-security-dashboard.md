# Keystone Auth — Full System Reference

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Auth Flow — 5 User Types](#2-auth-flow--5-user-types)
3. [Onboarding Flow](#3-onboarding-flow)
4. [Security & Account Screens](#4-security--account-screens)
5. [Dashboard](#5-dashboard)
6. [Route Guard Map](#6-route-guard-map)
7. [State Provider Map](#7-state-provider-map)
8. [Key Decisions & Fixes](#8-key-decisions--fixes)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        KEYSTONE ARCHITECTURE                        │
│                                                                      │
│  ┌──────────────────┐    ┌──────────────────┐    ┌───────────────┐  │
│  │    SCREENS        │    │    PROVIDERS      │    │   SERVICES    │  │
│  │  (40+ routes)     │───▶│  (Riverpod)      │───▶│              │  │
│  │                   │    │                  │    │ InternalAuth  │  │
│  │  Landing          │    │  authStateProvider│    │  ├─ Vault     │  │
│  │  PhoneEntry       │    │  mergedAuthState  │    │  ├─ Biometric│  │
│  │  OtpVerify        │    │  authNotifier     │    │  ├─ PIN      │  │
│  │  CreatePassword   │    │  currentUser      │    │  └─ TokenMgr │  │
│  │  PasswordEntry    │    │  profileProvider   │    │              │  │
│  │  BiometricEnroll  │    │  jobListProvider   │    │  DBSync      │  │
│  │  PinSetup         │    │  customerList      │    │  Connectivity│  │
│  │  PinEntry         │    │  remindersProvider │    └───────────────┘  │
│  │  Onboarding       │    └────────┬─────────┘           │             │
│  │  Transition       │             │                      │             │
│  │  Dashboard        │             ▼                      ▼             │
│  │  Profile          │    ┌────────────────────────────────────┐       │
│  │  Security         │    │         SUPABASE                    │       │
│  │  Hub              │    │  ┌──────────┐ ┌──────────┐         │       │
│  └──────────────────┘    │  │  Auth     │ │  DB      │         │       │
│                          │  │  (OTP,    │ │  users   │         │       │
│  ┌──────────────────┐    │  │  password) │ │  profiles│         │       │
│  │    GoRouter       │    │  └──────────┘ │  jobs    │         │       │
│  │  (redirect logic) │───▶│               │  custome │         │       │
│  └──────────────────┘    │               │  ...     │         │       │
│                          │               └──────────┘         │       │
│  ┌──────────────────┐    └────────────────────────────────────┘       │
│  │  TransitionScreen │                                               │
│  │  (gatekeeper)     │—— final decision point before dashboard       │
│  └──────────────────┘                                                │
└─────────────────────────────────────────────────────────────────────┘
```

## 2. Auth Flow — 5 User Types

### Type 1: Brand New User

```
LANDING
  │
  ▼
PHONE ENTRY ──checkAuthState──► {exists:false}
  │
  ▼
OTP VERIFY ──verifyOtp──► session created
  │                      authStateProvider.build() → hasProfile=false
  ▼
CREATE PASSWORD ──enrollPassword──► Supabase.updateUser(password)
  │
  ▼
BIOMETRIC ENROLL
  │  □ Fingerprint (optional)
  │  ■ APP PIN (mandatory) ──► PIN SETUP SCREEN
  │                                enrollPin() → vault has PIN
  │                                setLocallyUnlocked(true)  ← prevents double-auth
  ▼
TRANSITION (2nd pass)
  │  hasProfile=true, vault has PIN, isLocallyUnlocked=true
  │  → vault check → has PIN → DASHBOARD
  ▼
ONBOARDING ──completeOnboarding──► createUser + createProfile + password_created=true
  │
  ▼
TRANSITION (3rd pass)
  │  hasProfile=true, vault has PIN, isLocallyUnlocked=true
  ▼
DASHBOARD
```

**On Reopen:**
```
APP START → Transition → build() → session exists → skip 5s recovery (~50ms)
  → hasProfile=true, vault has PIN, isLocallyUnlocked=false
  → tryAutoLogin() → vault=PIN → UnlockLocked → /locked
  → PinEntry → unlockWithPin() → UnlockSuccess
  → setLocallyUnlocked(true) → /transition → /dashboard
```

---

### Type 2: Existing + Fully Setup

```
LANDING → PHONE ENTRY
  checkAuthState → {exists:true, hasPassword:true}
  │
  ▼
PASSWORD ENTRY
  verifyPassword() → Supabase.signInWithPassword
  session returned
  setLocallyUnlocked(true)       ← cloud password = verified identity
  authStateProvider.refresh()
  │
  ▼
TRANSITION
  hasProfile=true, isLocallyUnlocked=true (skips tryAutoLogin!)
  vault has PIN → DASHBOARD
```

**On Reopen:** Same as Type 1 reopen.

---

### Type 3: Existing + No Password (Jeremie)

```
LANDING → PHONE ENTRY
  checkAuthState → {exists:true, hasPassword:false}
  │
  ▼
OTP VERIFY
  verifyOtp() → session created
  authStateProvider.build():
    hasProfile=true
    identities=phone-only
    password_created=true (STALE — from old app version)
    SELF-HEALING: set password_created=false, needsUpgrade=true
  │
  ▼
CREATE PASSWORD (allowlisted when needsUpgrade=true)
  enrollPassword() → Supabase.updateUser — ACTUALLY sets the password
  │
  ▼
BIOMETRIC ENROLL → PIN SETUP (mandatory, PopScope blocks back)
  enrollPin() → setLocallyUnlocked(true)
  │
  ▼
TRANSITION → Vault has PIN → isLocallyUnlocked=true → DASHBOARD
```

---

### Type 4: Existing + Needs Upgrade

Same as Type 3, except `password_created=false` from the start. No self-healing needed.

---

### Type 5: Vault Wiped (new device)

```
LANDING → PHONE ENTRY → checkAuthState → {hasPassword:true}
  │
  ▼
PASSWORD ENTRY → verifyPassword() → session
  setLocallyUnlocked(true)
  │
  ▼
TRANSITION
  isLocallyUnlocked=true, vault.empty
  → mandatory PIN SETUP (no dialog, no skip, PopScope guard)
  → enrollPin() → setLocallyUnlocked(true)
  → biometricEnrollPage → CONTINUE → /transition
  → vault has PIN, isLocallyUnlocked=true → DASHBOARD
```

---

## 3. Onboarding Flow

```
OnboardingScreen (/auth/onboarding)
  3 steps, reachable from TransitionScreen gatekeeper when !hasProfile

  ┌─────────────────────────────────────────────────────────────────────┐
  │  STEP 0: NAME                                                       │
  │  ┌─────────────────────────────────────────────────────────────┐    │
  │  │  YOUR NAME                                                    │    │
  │  │  How should we address you?                                   │    │
  │  │                                                               │    │
  │  │  ● ● ○  ← step indicator (3 steps)                           │    │
  │  │                                                               │    │
  │  │  Full Name                                                    │    │
  │  │  ┌─────────────────────────────────────────┐                  │    │
  │  │  │  Kofi Amankwah                          │                  │    │
  │  │  └─────────────────────────────────────────┘                  │    │
  │  │                                                               │    │
  │  │  [          CONTINUE           ]                              │    │
  │  └─────────────────────────────────────────────────────────────┘    │
  │  ~ Checks: name.trim().length >= 2                                  │
  └─────────────────────────────────────────────────────────────────────┘
       │
       ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │  STEP 1: SERVICES                                                   │
  │  ┌─────────────────────────────────────────────────────────────┐    │
  │  │  YOUR SERVICES                                                │    │
  │  │  Select what you offer.                                       │    │
  │  │                                                               │    │
  │  │    ○  ●  ○   ← step indicator                                │    │
  │  │                                                               │    │
  │  │  ┌────────────────────────────────────────────────────────┐   │    │
  │  │  │  ○  CAR LOCK PROGRAMMING                              │   │    │
  │  │  └────────────────────────────────────────────────────────┘   │    │
  │  │  ┌────────────────────────────────────────────────────────┐   │    │
  │  │  │  ●  DOOR LOCK INSTALLATION                             │   │    │
  │  │  └────────────────────────────────────────────────────────┘   │    │
  │  │  ┌────────────────────────────────────────────────────────┐   │    │
  │  │  │  ○  SMART LOCK INSTALLATION                            │   │    │
  │  │  └────────────────────────────────────────────────────────┘   │    │
  │  │                                                               │    │
  │  │  [          CONTINUE           ]                              │    │
  │  └─────────────────────────────────────────────────────────────┘    │
  │  ~ Fetches service types from Supabase (serviceTypeProvider)        │
  │  ~ Groups by category                                               │
  │  ~ Validation: at least 1 service selected                          │
  └─────────────────────────────────────────────────────────────────────┘
       │
       ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │  STEP 2: TERMS                                                      │
  │  ┌─────────────────────────────────────────────────────────────┐    │
  │  │  TERMS & CONDITIONS                                           │    │
  │  │                                                               │    │
  │  │  ○  ○  ●   ← step indicator                                  │    │
  │  │                                                               │    │
  │  │  ┌─────────────────────────────────────────────────────┐     │    │
  │  │  │  [Terms content loaded from assets/legal/terms.md]  │     │    │
  │  │  │  Markdown rendered via flutter_markdown              │     │    │
  │  │  │                                                     │     │    │
  │  │  │  Scroll to bottom to enable I ACCEPT button...      │     │    │
  │  │  └─────────────────────────────────────────────────────┘     │    │
  │  │                                                               │    │
  │  │  [     I ACCEPT (scroll to bottom first)     ]                │    │
  │  └─────────────────────────────────────────────────────────────┘    │
  │  ~ Validation: must scroll to 98% of content                        │
  │  ~ termsVersion: RouteNames.currentTermsVersion (incremented on    │
  │    content change, currently = 1)                                   │
  └─────────────────────────────────────────────────────────────────────┘
       │
       ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │  COMPLETION                                                        │
  │  completeOnboarding(name, services, termsAcceptedAt, termsVersion)  │
  │                                                                      │
  │  [~] authRepo.createUser() → INSERT into `users` table              │
  │  [~] profileRepo.createProfile() → INSERT into `profiles` table     │
  │  [~] Supabase: UPDATE profiles SET password_created=true             │
  │  [~] authStateProvider.refresh() → hasProfile=true now              │
  │  [~] KsSuccessMoment.show("ONBOARDING COMPLETE")                    │
  │  [→] context.go(/transition)                                        │
  │                                                                      │
  │  On transition (2nd pass):                                           │
  │    hasProfile=true, vault has PIN, isLocallyUnlocked=true            │
  │    → DASHBOARD directly                                              │
  └─────────────────────────────────────────────────────────────────────┘
```

---

## 4. Security & Account Screens

### Security Screen (/profile/security)

```
┌─────────────────────────────────────────────────────────────────────┐
│  ACCOUNT & SECURITY                                                  │
│  ┌────────────────┬────────────────┬────────────────┐               │
│  │   Security     │    Account     │   Sessions      │               │
│  └────────────────┴────────────────┴────────────────┘               │
│                                                                      │
│  ── SECURITY TAB ──                                                  │
│  ┌──────────────────────────────────────────────┐                   │
│  │  PASSWORD                                     │                   │
│  │  ┌────────────────────────────────────────┐   │                   │
│  │  │  🔒  Change Password                    │   │                   │
│  │  │      Update your account password    >  │   │                   │
│  │  └────────────────────────────────────────┘   │                   │
│  │                                               │                   │
│  │  QUICK UNLOCK                                 │                   │
│  │  ┌────────────────────────────────────────┐   │                   │
│  │  │  🔍  Biometric Unlock                  │   │                   │
│  │  │      Fingerprint enabled          [ON] │   │                   │
│  │  └────────────────────────────────────────┘   │                   │
│  │  ┌────────────────────────────────────────┐   │                   │
│  │  │  🔒  PIN Unlock                        │   │                   │
│  │  │      PIN is set up                   > │   │                   │
│  │  └────────────────────────────────────────┘   │                   │
│  │                                               │                   │
│  │  ⚠  DANGER ZONE                               │                   │
│  │  ┌────────────────────────────────────────┐   │                   │
│  │  │  🗑  Delete Account                     │   │                   │
│  │  │      Permanently delete all data     >  │   │                   │
│  │  └────────────────────────────────────────┘   │                   │
│  └──────────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────────┘

DATA FLOW (Security Tab):
  initState → _loadMethod()
    [~] vault.getEnrolledMethod() → AuthMethod.pin/biometric/none
    [~] vault.getHasBiometric()   → bool (separate flag, survives PIN overwrite)
    → setState: _enrolledMethod, _hasBiometric, _loading=false

  TOGGLE BIOMETRIC ON:
    _toggleBiometric(true)
      [~] service.enrollBiometric()
          → biometric.authenticateWithBiometrics() (system dialog, 30s timeout)
          → vault.storeEnrolledMethod(AuthMethod.biometric)
          → vault.storeHasBiometric(true)
      → _loadMethod() → refresh display

  TOGGLE BIOMETRIC OFF:
    _toggleBiometric(false)
      [~] service.clearVault()
      → _loadMethod()

  SETUP PIN:
    _setupPin()
      [~] vault.getEnrolledMethod()
      → if PIN already exists: /auth/pin-entry (verify first)
      → if no PIN: /auth/pin-setup
      → PIN is mandatory only during onboarding/mandatory flow
      → From Security screen, PIN is optional (user-initiated)
```

### Change Password Sheet

```
  showModalBottomSheet
  ┌─────────────────────────────────────────────────────────────────────┐
  │  CHANGE PASSWORD                                                    │
  │                                                                      │
  │  Current Password  ┌──────────────────────────────────────┐         │
  │                    │  ****************                    │         │
  │                    └──────────────────────────────────────┘         │
  │                                                                      │
  │  New Password      ┌──────────────────────────────────────┐         │
  │                    │  ****************                    │         │
  │                    └──────────────────────────────────────┘         │
  │                                                                      │
  │  Confirm Password  ┌──────────────────────────────────────┐         │
  │                    │  ****************                    │         │
  │                    └──────────────────────────────────────┘         │
  │                                                                      │
  │  [        CHANGE PASSWORD        ]                                  │
  │                                                                      │
  │  ✓ Minimum 8 characters                                              │
  │  ✓ At least 1 letter                                                 │
  │  ✓ At least 1 number                                                 │
  │  ✓ Passwords match                                                   │
  └─────────────────────────────────────────────────────────────────────┘

  [~] authNotifier.changePassword(current, new)
      → supabase.auth.signInWithPassword(phone, current)  // re-auth
      → supabase.auth.updateUser(password: new)
```

### Account Tab

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │  ── ACCOUNT TAB ──                                                   │
  │                                                                      │
  │  ACCOUNT INFO                                                        │
  │  ┌────────────────────────────────────────┐                         │
  │  │  📞  Phone Number                      │                         │
  │  │      +233 53 456 7890               >  │                         │
  │  └────────────────────────────────────────┘                         │
  │  ┌────────────────────────────────────────┐                         │
  │  │  📅  Account Created                   │                         │
  │  │      2026-03-21                     >  │                         │
  │  └────────────────────────────────────────┘                         │
  │                                                                      │
  │  DATA                                                                 │
  │  ┌────────────────────────────────────────┐                         │
  │  │  ⬇  Export My Data                     │                         │
  │  │      Download all your data as JSON     │                         │
  │  └────────────────────────────────────────┘                         │
  │      → DataExportService.exportAsJson()    │                         │
  └─────────────────────────────────────────────────────────────────────┘
```

### Sessions Tab

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │  ── SESSIONS TAB ──                                                  │
  │                                                                      │
  │  ACTIVE SESSIONS                                                     │
  │  ┌────────────────────────────────────────┐                         │
  │  │  ✓  This Device                        │                         │
  │  │     Current session                    │                         │
  │  └────────────────────────────────────────┘                         │
  │                                                                      │
  │  [   Sign out of all other devices   ]                               │
  │      → supabase.auth.signOut(scope: SignOutScope.others)             │
  └─────────────────────────────────────────────────────────────────────┘
```

---

## 5. Dashboard

```
┌─────────────────────────────────────────────────────────────────────┐
│  KsAppBar                                                           │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  DASHBOARD                              🔔 3   👤           │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐                           │
│  │  TODAY           │  │  MONTH           │                           │
│  │  GHS 0           │  │  GHS 0           │                           │
│  │  0 jobs today    │  │  0 jobs this mo  │                           │
│  └─────────────────┘  └─────────────────┘                           │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  📊  MONTHLY TARGET                           0%          │    │
│  │  ▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                 │    │
│  │  of GHS 0 target                                          │    │
│  │  (tap to edit via bottom sheet)                            │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  (reminder chips — only if reminders exist)                          │
│  ┌────────┐ ┌──────┐ ┌──────────┐ ┌───────────┐                    │
│  │2 unpaid│ │1 stuck│ │3 follow-u│ │1 recurring│                    │
│  └────────┘ └──────┘ └──────────┘ └───────────┘                    │
│                                                                      │
│  TODAY'S JOBS                                                        │
│  (list of today's jobs — or empty state if none)                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  📅  NO JOBS TODAY                                          │    │
│  │       Tap + to log your first job today.                    │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  FOLLOW-UPS (if reminders exist)                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  🕐  FOLLOW-UPS                                        >  │    │
│  │  📄  2 unpaid invoices                                     │    │
│  │  ⚡  1 job still in progress                                │    │
│  │  💬  3 customers awaiting follow-up                         │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  TOOLS                                                              │
│  ┌──────┐ ┌──────┐ ┌──────┐                                        │
│  │ 📈   │ │ 📦   │ │ 📓   │                                        │
│  │ ANAL │ │ INVEN│ │ KNOW │                                        │
│  ├──────┤ ├──────┤ ├──────┤                                        │
│  │ ⚡   │ │ 🎯   │ │ 📋   │                                        │
│  │ ACTIV│ │ PRIC │ │ TEMPL│                                        │
│  └──────┘ └──────┘ └──────┘                                        │
│                                                                      │
│  QUICK ACTIONS                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  +  NEW JOB                                    >          │    │
│  │     Log a new service job                                    │    │
│  └────────────────────────────────────────────────────────────┘    │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  👤  NEW CUSTOMER                              >          │    │
│  │     Add a customer record                                   │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ─────────────────────────────────────────────────────────────      │
│  DASHBOARD    JOBS    CUSTOMERS    HUB                               │
└─────────────────────────────────────────────────────────────────────┘

DATA FLOW (Dashboard load):
  JobListNotifier.load()
    [~] getJobs(includeArchived: false) → active jobs
    [~] getJobs(includeArchived: true)  → all jobs (for count)
    ↓
    getJobs() in JobRepositoryImpl:
      [D] isOnline?
        YES → [~] remote.getJobs(userId: auth_id)
               ↓
               [D] success?
                 YES → save to local cache, return combined
                 NO  → [D] local cache has data?
                          YES → serve from cache
                          NO  → RETHROW error → UI shows "Could not load jobs"
        NO  → [~] local.getJobs() (from Hive)
    ↓
    Today: filter by jobDate == today
    Month: filter by jobDate. month == current month
    Revenue: fold amountCharged by period
    Reminders: refresh from ReminderWorker
```

---

## 6. Route Guard Map

```
GoRouter redirect EVALUATION ORDER
(called on EVERY route transition via _routerRefreshNotifier)

  0. PUBLIC PROFILE
     path.startsWith('/p/') → null (allow always)

  1. APP OUTDATED
     Hive(auth).app_is_outdated == true → /auth/version-gate

  2. UNAUTHENTICATED
     !isLoggedIn
       ├── in authPaths? → null (allow auth screens)
       └── /landing

  3. LOGGED IN + NO PROFILE
     isLoggedIn && !hasProfile
       ├── path in [onboarding, biometricEnroll, createPassword, pinSetup]? → null
       └── /auth/onboarding

  4. NEEDS PASSWORD UPGRADE
     isLoggedIn && hasProfile && needsUpgrade
       ├── path == upgradePath? → null
       ├── path == createPassword? → null  ← NEW: allowlist for OTP users
       ├── alreadyUpgraded in Hive? → null
       └── /auth/upgrade

  5. FULLY AUTHENTICATED
     isLoggedIn && hasProfile
       ├── isPublicProfile? → null
       │
       ├── LOCAL SECURITY FIRST
       │   path in [biometricEnroll, pinSetup, locked, pinEntry]? → null
       │
       ├── DATA SYNC CHECK
       │   sync done? → next
       │   path == initialSync? → null
       │   else → /auth/initial-sync
       │
       ├── AUTH PATH CLEANUP
       │   path in authPaths OR isOnboarding OR isPasswordUpgrade?
       │   → /transition  ← was: /dashboard (the bug)
       │
       └── null (stay on current route)
```

---

## 7. State Provider Map

```
┌─────────────────────────────────────────────────────────────────────┐
│  PROVIDER                   │ TYPE              │ WATCHED BY        │
├─────────────────────────────────────────────────────────────────────┤
│  authStateProvider           │ AsyncNotifier      │ TransitionScreen  │
│                              │ <AuthState>        │ GoRouter          │
│                              │                    │ passwordEntry     │
│                              │                    │ pinSetup          │
│                              │                    │ pinEntry          │
│                              │                    │ lockedScreen      │
├──────────────────────────────┼────────────────────┼──────────────────┤
│  mergedAuthStateProvider     │ Provider           │ GoRouter          │
│                              │ <AsyncValue<       │ (dev mode         │
│                              │  AuthState>>       │  overrides)       │
├──────────────────────────────┼────────────────────┼──────────────────┤
│  authNotifierProvider        │ StateNotifier      │ phoneEntry,       │
│                              │ <AuthUiState>      │ otpVerify,        │
│                              │                    │ createPassword,   │
│                              │                    │ passwordEntry,    │
│                              │                    │ onboarding        │
├──────────────────────────────┼────────────────────┼──────────────────┤
│  currentUserProvider         │ FutureProvider     │ logJobScreen,    │
│                              │ <UserEntity?>      │ inventoryScreen,  │
│                              │                    │ profileScreen,    │
│                              │                    │ dashboard,        │
│                              │                    │ keyCodesScreen,   │
│                              │                    │ templates,        │
│                              │                    │ permissions,      │
│                              │                    │ recurringJobs,    │
│                              │                    │ hub               │
│                              │                    │                   │
│                              │  FIXED: .id now    │                   │
│                              │  returns authId    │                   │
│                              │  (not internal     │                   │
│                              │   users.id)        │                   │
├──────────────────────────────┼────────────────────┼──────────────────┤
│  profileProvider             │ StateNotifier      │ TransitionScreen  │
│                              │ <ProfileState>     │ dashboard,        │
│                              │                    │ profileScreen,    │
│                              │                    │ onboarding        │
├──────────────────────────────┼────────────────────┼──────────────────┤
│  jobListProvider             │ StateNotifier      │ dashboard,        │
│                              │ <JobListState>     │ jobListScreen,    │
│                              │                    │ customerDetail,   │
│                              │                    │ hub,              │
│                              │                    │ noteDetail,       │
│                              │                    │ reminders,        │
│                              │                    │ noteJobLink       │
├──────────────────────────────┼────────────────────┼──────────────────┤
│  customerListProvider        │ StateNotifier      │ dashboard,        │
│                              │                    │ customerList,     │
│                              │                    │ customerDetail    │
├──────────────────────────────┼────────────────────┼──────────────────┤
│  remindersProvider           │ StateNotifier      │ dashboard,        │
│                              │ <ReminderState>    │ remindersScreen   │
├──────────────────────────────┼────────────────────┼──────────────────┤
│  jobRemoteDatasourceProvider │ Provider           │ JobRepositoryImpl │
│                              │ <JobRemoteDS>      │                   │
├──────────────────────────────┼────────────────────┼──────────────────┤
│  supabaseClientProvider      │ Provider           │ ALL data layers   │
│                              │ <SupabaseClient>   │                   │
└──────────────────────────────┴────────────────────┴──────────────────┘

AuthState fields:
  session              : Session?  — null = unauthenticated
  hasProfile           : bool      — profile row exists in DB
  isLoading            : bool      — build() still running
  needsPasswordUpgrade : bool      — isPhoneOnly (Supabase identities)
  isLocallyUnlocked    : bool      — vault PIN not required THIS session
                                    (true = already verified this session)

AuthUiState fields (wizard screens):
  isLoading           : bool
  errorMessage        : String?
  phoneNumber         : String?
  isOtpSent           : bool
  hasProfile          : bool?
  isPasswordCreated   : bool

AuthMethod enum:
  none       — no local credentials
  biometric  — fingerprint/face enrolled (may coexist with PIN)
  pin        — custom 6-digit PIN in vault
  password   — Supabase password (not stored locally)

UnlockResult sealed class:
  UnlockSuccess       — device unlocked, proceed
  UnlockLocked        — needs PIN/biometric
  UnlockNeedsNetwork  — no credentials, sign in required
  UnlockNeedsOnline   — vault stale/wiped, needs re-auth
```

---

## 8. Key Decisions & Fixes

| # | Fix | File | Why |
|---|-----|------|-----|
| 1 | `_getInternalUserId()` returns `auth_id` | `job_repository_impl.dart` | Jobs stored `auth_id` but query used internal `users.id` |
| 2 | `currentUserProvider.id` returns `authId` | `auth_provider.dart` | All FK refs in other tables use `auth_id` |
| 3 | `getJobs()` surfaces error when cache empty | `job_repository_impl.dart` | Silent catch showed empty dashboard with no error |
| 4 | Security screen reads `getHasBiometric()` | `security_screen.dart` | PIN enrollment overwrote vault method, biometric appeared disabled |
| 5 | `unlockWithDeviceAuth()` checks `hasBiometric` | `internal_auth_service.dart` | Lock screen skipped biometric when vault method was PIN |
| 6 | GoRouter whitelists local security paths | `app_router.dart` | Auth routes redirected to dashboard, vaporizing setup screens |
| 7 | Auth path cleanup → `/transition` not `/dashboard` | `app_router.dart` | Router bypassed tryAutoLogin gatekeeper |
| 8 | `createPassword` allowlisted when needsUpgrade | `app_router.dart` | Existing users sent to transition instead of password creation |
| 9 | PIN mandatory after biometric on password entry | `password_entry_screen.dart` | Biometric-only escape left users with no PIN fallback |
| 10 | 30s biometric timeout | `internal_auth_service.dart` | System fingerprint dialog could hang indefinitely |
| 11 | Transition screen 5s profile fallback | `transition_screen.dart` | ProfileProvider hang blocked gatekeeper forever |
| 12 | Self-healing password_created check | `auth_provider.dart` | Stale profile flag skipped password creation for phone-only users |
| 13 | Removed SKIP from Quick Unlock dialog | `transition_screen.dart` | Users could bypass PIN setup entirely |
| 14 | Removed SKIP from Fast Unlock dialog | `password_entry_screen.dart` | Same — security loophole |
| 15 | PopScope guard on PIN setup | `pin_setup_screen.dart` | Android back button created redirect loop |
| 16 | `setLocallyUnlocked(true)` after PIN enroll | `pin_setup_screen.dart` | User forced to re-enter PIN they just created |
| 17 | Skip 5s session recovery when session exists | `auth_provider.dart` | Cold start penalty eliminated for returning users |
