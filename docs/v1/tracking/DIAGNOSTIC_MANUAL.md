# KEYSTONE DIAGNOSTIC MANUAL
*Version 1.2 - Supabase & Identity Special Edition*

## I. SUPABASE ERROR CODES & REMEDIES

### Code 23503: Foreign Key Violation
- **Context:** Occurs when inserting a Job, Customer, or Profile.
- **Cause:** You are likely passing the **Auth UID** to a column that expects the **Internal UUID**.
- **Remedy:** Check  ID Matrix. Use  to get the correct internal ID.

### Code 42501: RLS Violation (Permission Denied)
- **Context:** Select/Insert fails even when logged in.
- **Cause:** The RLS policy for that table is likely 'Nested' (checking a different table for ownership).
- **Remedy:** Verify if the user has a record in . If not, the nested lookup will return 0 rows, causing an RLS fail.

### Code 23505: Unique Constraint Violation
- **Context:** 'duplicate key value violates unique constraint "users_auth_id_key"'.
- **Cause:** Onboarding failed halfway. A record exists in  but not in .
- **Remedy:** The  is now idempotent. It will automatically detect the existing user and proceed to profile creation.

## II. CORE FEATURE LOGIC

### 133. lib/features/auth/domain/usecases/verify_otp_usecase.dart
- **Critical Logic:** Normalizes phone number to E.164.
- **Failure Mode:** Verification fails with 'Invalid phone number format' if normalization is skipped.

### 134. lib/core/providers/auth_provider.dart ()
- **Objective:** The bridge between Supabase Auth and our Application Data.
- **Criticality:** High. This is the only way to get the **Internal UUID** required for logging jobs and customers.
- **Failure Mode:** Returns null if the  record is missing.

### 135. lib/core/router/app_router.dart
- **Objective:** Route registry and Auth-guarded redirects.
- **Failure Mode:** Navigation crash ('No initial matches') if a new screen is added but not registered in the  array.



## I. ROOT ARCHITECTURE
... (entries 1-58) ...

### 59. lib/features/auth/presentation/screens/onboarding_screen.dart
- **Objective:** The "Technician Birthplace" coordinator.
- **Core Logic:** Manages step-based state (Name vs Services) and delegates UI to modular widgets.
- **Failure Mode:** Navigation fails if `authNotifierProvider.completeOnboarding` returns false.

## III. FEATURE WIDGETS
... (entries 60-128) ...

### 129. lib/features/auth/presentation/widgets/name_step_view.dart
- **Objective:** UI for identity collection.

### 130. lib/features/auth/presentation/widgets/services_step_view.dart
- **Objective:** UI for service category selection.

### 131. lib/features/auth/presentation/widgets/onboarding_bottom_bar.dart
- **Objective:** Persistent action anchor for onboarding steps.

### 132. lib/features/auth/presentation/widgets/onboarding_step_indicator.dart
- **Objective:** Visual progress for the 2-step flow.

### lib/features/technician_profile/data/datasources/profile_remote_datasource.dart
- **Responsibility:** Direct Supabase communication for profile data and storage.
- **Talks to:** Supabase (profiles table, storage)
- **Breaks if missing:** Onboarding and profile management fail.

### lib/features/technician_profile/data/repositories/profile_repository_impl.dart
- **Responsibility:** Maps entities to models and enforces ID consistency.
- **Talks to:** ProfileRemoteDatasource, Supabase Auth
- **Breaks if missing:** Critical ID mismatch causes Foreign Key failures on onboarding.

### lib/features/auth/presentation/screens/landing_screen.dart
- **Objective:** Brand introduction and initial entry point.
- **Core Logic:** Staggered animations for brand elements; redirects to phone entry.
- **Modularity:** Pure UI coordinator; no business logic.

### lib/features/auth/presentation/screens/phone_entry_screen.dart
- **Objective:** Identity initiation via phone number.
- **Core Logic:** Validates Ghana phone format; triggers OTP request.
- **Modularity:** Separates input handling from auth logic.

### lib/features/auth/presentation/screens/otp_verify_screen.dart
- **Objective:** Identity verification.
- **Core Logic:** Manages 6-digit PIN input and resend cooldown timer.
- **Modularity:** Uses Pinput for specialized field behavior.

### lib/features/auth/presentation/providers/auth_notifier.dart
- **Objective:** Orchestrates UI state for the entire authentication and onboarding lifecycle.
- **Critical Dependency:** Requires `RequestOtpUsecase`, `VerifyOtpUsecase`, `ProfileRepository`, and `AuthRepository`.
- **Modularity:** Successfully encapsulated all dependency injection within the file to resolve identifier errors.

### lib/core/router/app_router.dart
- **Objective:** Guards application routes based on asynchronous authentication state.
- **Failure Mode:** Redirect logic fails if `authStateProvider` (AsyncValue) is not correctly unwrapped before checking `isAuthenticated`.

### lib/core/constants/supabase_constants.dart
- **Objective:** Centralized configuration for Supabase environment variables and table names.
- **Failure Mode:** Empty URL or Key causes `No host specified` error during API calls. Ensure values are hardcoded or passed correctly via `--dart-define`.

## III. UI RENDERING & VISUAL FIXES

### Input Text Visibility (White-Out Bug)
- **Context:** Occurs when using `TextField` or `KsTextField` inside a dark container (like `Primary800`).
- **Cause:** The default `InputDecoration` fill properties can clash with parent container backgrounds, making white text appear invisible or highlighting the field with a solid white block.
- **Remedy:** Ensure `filled: true` and `fillColor: Colors.transparent` are set within the `InputDecoration`. This allows the dark `Primary800` background of the parent `Container` to show through while maintaining the correct text contrast.

## IV. RUNTIME & PATHING RESOLUTIONS

### Enum String Conversion (NoSuchMethodError: 'name')
- **Context:** Occurs when calling `.name` on a ServiceType enum in older or specific Dart environments.
- **Remedy:** Use `serviceType.toString().split('.').last` for a robust string extraction.

### Relative Path Leveling
- **Context:** `lib/features/customer_history/presentation/screens/`
- **Error:** "Error when reading... No such file or directory"
- **Logic:** When jumping between features from deep screen folders, use `../../../` to reach the `lib/features/` root before descending into a different feature folder.

### Identity Mapping (whatsappNumber)
- **Error:** "Getter 'phoneNumber' isn't defined for ProfileEntity"
- **Remedy:** The `ProfileEntity` explicitly uses `whatsappNumber`. Use this field for all profile-related identity displays.

## V. SUPABASE CLI & TESTING ENVIRONMENT

### Supabase CLI Installation on Pop OS Linux
- **Context:** CLI shows command not found after npm install attempt
- **Cause:** npm install -g supabase is not supported. curl script returns 404.
- **Remedy:** Download binary directly:
  wget -qO- https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar xvz -C /tmp
  sudo mv /tmp/supabase /usr/local/bin/supabase
  supabase --version

### supabase db execute Not Found
- **Context:** Trying to run SQL directly via CLI
- **Cause:** CLI version 2.78.1 does not have db execute subcommand
- **Remedy:** Create a migration file and push it:
  supabase migration new fix_description
  Then write SQL into the migration file
  Then run: supabase db push --linked

### mocktail TypeError on any() with Custom Types
- **Context:** Flutter test fails with TypeError when using any() matcher
- **Cause:** mocktail needs a fallback value for every custom type used with any()
- **Remedy:** Add before your test group:
  class FakeJobEntity extends Fake implements JobEntity {}
  setUpAll(() { registerFallbackValue(FakeJobEntity()); });

### MockUrlLauncher Platform Interface Assertion Failed
- **Context:** Test setup fails with platform interface assertion error
- **Cause:** Plugin platform interfaces reject implements-only mocks
- **Remedy:** Use MockPlatformInterfaceMixin:
  class MockUrlLauncher extends Mock with MockPlatformInterfaceMixin implements UrlLauncherPlatform {}

### launchUrl Mock Argument Mismatch
- **Context:** mocktail throws invalid argument error on launchUrl stub
- **Cause:** launchUrl requires exactly two positional arguments
- **Remedy:** when(() => mockUrlLauncher.launchUrl(any(), any())).thenAnswer((_) async => true);
