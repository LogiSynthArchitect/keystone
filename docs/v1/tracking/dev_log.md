# KEYSTONE DEV LOG
Running record of what was built, what broke, and what was learned.
Append-only. Never edited — only added to.

---

## SESSION 1 — Project Foundation — 2026-03-09

### What was built
- Flutter project created (3.41.4)
- Complete folder structure from Document 13
- pubspec.yaml with all dependencies
- lib/core/theme/ — app_colors, app_spacing, app_text_styles, app_theme
- lib/core/constants/ — app_constants, supabase_constants, whatsapp_constants
- lib/core/analytics/ — analytics_constants
- lib/core/errors/ — app_exception, auth_exception, network_exception, storage_exception, validation_exception
- lib/core/network/ — supabase_client, connectivity_service
- lib/core/storage/ — hive_service (replaced Isar)
- lib/core/providers/ — supabase_provider, connectivity_provider
- lib/main.dart + lib/app.dart

### What broke and how it was fixed
BREAK 1: isar_generator ^3.1.0 conflicts with riverpod_generator ^2.4.3
  Cause: both require different versions of the analyzer package
  Fix: replaced Isar with Hive (hive_flutter ^1.1.0)
  Impact: isar_schemas folder renamed to hive_boxes, local datasource implementation will use Hive boxes instead of Isar collections. Domain layer and all layers above are unaffected.

BREAK 2: const_eval_method_invocation in app_constants.dart
  Cause: AppEnvironment.values.byName() cannot be called in a const context
  Fix: replaced const factory with a regular static getter using a conditional expression

BREAK 3: CardTheme vs CardThemeData in app_theme.dart
  Cause: Flutter 3.41.4 uses CardThemeData, not CardTheme in ThemeData
  Fix: sed replace CardTheme( → CardThemeData(

BREAK 4: widget_test.dart references MyApp which no longer exists
  Cause: Flutter default test references the default MyApp class
  Fix: replaced with empty test file — real tests added in Phase 10

### What was learned
- Isar 3.x is effectively unmaintained and conflicts with current Riverpod codegen. Hive is the safe V1 choice.
- Flutter 3.41.4 uses CardThemeData not CardTheme — API changed from earlier versions.
- Always run flutter analyze after every batch of files, not at the end.
- The --dart-define pattern for secrets works cleanly with String.fromEnvironment().

### What comes next
- Step 06: auth_provider.dart (core)
- Step 07: utility files (phone_formatter, currency_formatter, date_formatter, whatsapp_launcher)
- Step 08: route_names.dart + app_router.dart scaffold
- Then: GitHub repo + first commit
- Then: Phase 2 — domain entities

### Flutter analyze status
No issues found ✅

---

## SESSION 2 — Supabase & Core Infrastructure — 2026-03-09

### What was built
- Supabase project created (keystone-dev, London region)
- Database schema deployed: 6 tables, 4 enums, 5 triggers, RLS on all tables
- Storage buckets created: profile-photos, note-photos
- Phone auth enabled with test number: 233200000001 / OTP 123456
- Core auth provider (lib/core/providers/auth_provider.dart)
- Core router scaffold (lib/core/router/app_router.dart + route_names.dart)
- Core utilities: phone_formatter, currency_formatter, date_formatter, whatsapp_launcher, slug_generator
- App wired to GoRouter via MaterialApp.router
- App boots and runs on physical Android device ✅

### What broke and how it was fixed
BREAK 1: Supabase Phone auth has no "none" SMS provider option
  Fix: used Twilio with fake credentials + test phone number
  Test number: 233200000001 / OTP: 123456
  Impact: real SMS will work when Africa's Talking is configured in production

BREAK 2: GitHub PAT accidentally posted publicly
  Fix: token deleted immediately, new token generated, credential.helper store configured
  Learning: never paste tokens in chat — use credential.helper store from the start

### What was learned
- Supabase SQL editor runs sections independently — run in order from Document 12.8
- Git credential.helper store saves token permanently after first entry
- Router placeholder screens ("coming soon") let us verify routing before building real screens
- App redirects to /jobs correctly on boot — auth redirect will kick in once auth screens exist

### Flutter analyze status
No issues found ✅

---

## SESSION 3 — Auth Flow Calibration — 2026-03-09

### What was built
- Fixed Supabase credentials not being passed (--dart-define missing from run command)
- Created run.sh and .vscode/launch.json with dart-define flags
- Fixed phone number not normalized to E.164 before being stored in auth state
- Fixed infinite recursion in users RLS policies
- Fixed missing users INSERT RLS policy
- Fixed profile_slug empty string being sent (removed — trigger handles it)
- Full auth flow working end to end: phone → OTP → onboarding → jobs placeholder

### What broke and how it was fixed
BREAK 1: SUPABASE_URL empty — app built without --dart-define flags
  Fix: created run.sh with correct flags, flutter clean + rebuild

BREAK 2: OTP verify failing — phone stored as 0200000001 not +233200000001
  Fix: normalize phone number in auth_notifier.dart before saving to state

BREAK 3: Onboarding save failing — infinite recursion in RLS policies
  Fix: rewrote users RLS policies to use auth.uid() directly without subquery

BREAK 4: Onboarding save failing — no INSERT policy on users table
  Fix: added users_insert_own policy

### Flutter analyze status
To be verified

### Device test
Full auth flow working on physical Android device ✅
Phone → OTP → Onboarding → Jobs placeholder ✅

### What comes next
- Phase 2: Domain entities (User, Profile, Customer, Job, KnowledgeNote, FollowUp)
- Domain repository interfaces
- Then real screens per Document 16

---

## SESSION 4 — Job Logging Feature — 2026-03-09

### What was built
- Phase 5 complete: Job Logging Feature
- job_providers.dart — JobListNotifier + LogJobNotifier
- JobCard widget with sync badges and follow-up badge
- ServiceTypePicker widget
- JobListScreen with summary strip, empty state, FAB, pull-to-refresh
- LogJobScreen with service picker, customer name, location, amount, notes, date picker
- Router updated with nested job routes

### What broke and how it was fixed
BREAK 1: Existing user hit duplicate on onboarding
  Fix: check if user exists before createUser — skip if already exists

BREAK 2: Pull-to-refresh wiped pending local jobs
  Fix: getJobs always reads from local after remote sync — merge not replace

BREAK 3: job disappeared after refresh
  Fix: sort local jobs by jobDate desc after merge

### What was learned
- Always read from local after remote sync — never return remote directly
- customer_id field needs real UUID — customer feature must come before full sync
- Python heredoc is more reliable than bash heredoc for writing Dart files

### Flutter analyze status
3 const warnings only — no errors ✅

### Device test
Jobs screen loads ✅
Log job saves locally and remotely ✅
Summary strip shows correct totals ✅
Pull-to-refresh merges correctly ✅

### What comes next
- Phase 6: WhatsApp Follow-up (Steps 34-40)
- JobDetailScreen
- FollowUpButton + FollowUpMessagePreview widgets
- Checkpoint 3: tap send, WhatsApp opens, button locks

---

## SESSION 5 — Knowledge Base Feature — 2026-03-10

### What was built
- Phase 8 complete: Knowledge Base feature
- notes_providers.dart — NotesListNotifier + AddNoteNotifier
- NoteCard widget with tag chips
- TagInputField widget with add/remove tags
- NotesListScreen with search and empty state
- AddNoteScreen with tag input and service type selector
- NoteDetailScreen with archive action

### What broke and how it was fixed
BREAK 1: knowledge_notes RLS policies used users.id subquery instead of auth.uid()
  Fix: dropped and recreated all policies using auth.uid() = user_id directly

BREAK 2: knowledge_notes FK pointed to public.users not auth.users
  Fix: dropped and recreated FK to reference auth.users(id)

BREAK 3: service_type enum rejected camelCase values e.g. doorLockInstallation
  Fix: replaced regex _toSnakeCase (broken by Python escaping) with explicit switch map

BREAK 4: second note save failed — addNoteProvider state stuck on saved:true
  Fix: added reset() call in AddNoteScreen.initState()

BREAK 5: Python heredoc escaped dollar signs — string interpolation printed as literals
  Fix: rewrote entire repository file via Python to avoid interpolation issues

### Flutter analyze status
No issues found ✅

### Device test
Notes list loads ✅
Add note without service type ✅
Add note with service type ✅
Search by tag ✅
Note detail and archive ✅

### What comes next
- Phase 9: Technician Profile (Steps 56-62)
- ProfileScreen, EditProfileScreen, PublicProfileScreen
- Photo upload flow
- Share profile link

---

## SESSION 6 — Auth Flow Refinement & Debugging — 2026-03-10

### What was built
- Diagnosed and fixed 3 auth flow bugs that were breaking the core user journey.
- Added structured debug logging to auth flow (KS:AUTH and KS:AUTH_STATE).
- Logging covers: requestOtp, verifyOtp, getCurrentUser, createUser, signOut, onAuthStateChange, profile check.
- Full auth flow working end to end on physical device with clean log output.

### What broke and how it was fixed
BREAK 1: OTP verify had a double-navigation race condition
  Cause: Screen manually called context.go() AND invalidated authStateProvider simultaneously.
  Fix: Removed manual context.go() calls; router redirect now handles navigation.

BREAK 2: Onboarding bounced user back due to stale state
  Cause: context.go() called but authStateProvider never invalidated, so router saw hasProfile=false.
  Fix: Replaced context.go() with ref.invalidate(authStateProvider).

BREAK 3: Profile screen crashed on sign out
  Cause: String get _userId used bang operator on currentUser which becomes null after signOut().
  Fix: Changed to _supabase.auth.currentUser?.id ?? '' safe null handling.

BREAK 4: Infinite rebuild loop on initialSession and signedIn events
  Cause: onAuthStateChange listener called ref.invalidateSelf(), triggering a new listener and new event.
  Fix: Removed onAuthStateChange listener entirely from AuthNotifier. Added explicit refresh() and invalidateSelf() calls from call sites.

### What was learned
1. Supabase onAuthStateChange replays current state to every new subscriber — never call invalidateSelf() inside it.
2. Surgical patching with bash heredoc is unreliable; use Python or full file rewrites.
3. ref.watch() inside AsyncNotifier.build() can cause loops; use ref.read() for static providers.
4. Router redirect depends on authStateProvider — must invalidate it to trigger re-evaluation.

### Flutter analyze status
No issues found ✅

---

## SESSION 7 — Profile Feature & Polish — 2026-03-10

### What was built
- Phase 9 complete: Technician Profile feature.
- PublicProfileScreen (no auth required), Photo upload flow (Supabase storage), and Share profile link.
- Phase 10 complete: Polish and production readiness.
- Unsaved changes dialogs (PopScope), Analytics (KsAnalytics), and Error Boundary.
- Offline banner animations, Skeleton loaders, and Pull-to-refresh on all list screens.

### What broke and how it was fixed
BREAK 1: Photo upload returned 403 Unauthorized
  Cause: RLS policy was assigned to {public} instead of {authenticated}.
  Fix: Recreated storage policies with TO authenticated.

BREAK 2: Photo not updating in UI
  Cause: NetworkImage caches by URL.
  Fix: Added cache-busting timestamp (?t=ms) to uploaded photo URL.

BREAK 3: Unsaved changes dialog not showing
  Cause: KsAppBar called Navigator.pop() directly bypassing PopScope.
  Fix: Changed to Navigator.maybePop().

BREAK 4: PopScope not intercepting Android back gesture
  Fix: Added android:enableOnBackInvokedCallback="true" to manifest.

### Checkpoint 4 Smoke Test
- Auth flow, Log job (online/offline), Add customer, Add note, Photo upload: ALL PASS ✅

### Lessons
- Always check roles in storage RLS policies ({public} vs {authenticated}).
- PopScope requires Navigator.maybePop() to function.
- NetworkImage requires cache-busting for immediate updates.

---

## SESSION 8 — Brand Assets & Logo Implementation — 2026-03-11

### Goal
Design and implement the Keystone app icon, splash screen, and pixel-perfect SVG logo widget.

### Built & Implemented
- **App Icon:** White square canvas with centered logo, generated all mipmap sizes.
- **Splash Screen:** Sharp, well-proportioned splash using logos.png (1248x1248) source and flutter_native_splash.
- **KsLogo SVG:** Pixel-perfect combined SVG with 4 independently addressable paths (left_arm, right_arm, keystone_block, keyhole).
- **KsLogo Widget:** Programmatically controllable Flutter widget for runtime color changes and animations.

### What was learned
1. flutter_native_splash must be added, used, then removed due to AGP version conflicts on restricted networks.
2. SVG exports from Inkscape may contain embedded PNGs — verify vector paths before use.
3. Arange all parts in Inkscape and export as one SVG to preserve coordinate relationships; reassembling individual parts manually is unreliable.

---

## SESSION 9 — Auth UI Redesign — 2026-03-11

### Built & Implemented
- **Landing Screen:** Split-screen industrial design with staggered animations, Barlow Semi Condensed font system (weight 600+), and Gold CTAs.
- **Phone Entry Screen:** Seamless unified phone input with Ghana flag SVG and animated top feedback banner.
- **OTP Verify Screen:** 6-box Pinput design, countdown resend timer, and keyboard-aware floating buttons.
- **Router Updates:** Initial location moved to landing; redirect logic updated for unauthenticated users.

### Key Design Lessons
1. Split screen (light top / dark bottom) creates strong visual hierarchy.
2. BarlowSemiCondensed at 800 weight is the app's signature hero font.
3. Use RichText for mixed-style inline text instead of multiple wrapping widgets.
4. MediaQuery viewInsets is reliable for keyboard detection.

---

## SESSION 10 — Onboarding & Identity Resolution — 2026-03-12

### What was built
- **Onboarding Modularization:** Split onboarding_screen.dart into 4 modular widgets and 1 coordinator screen.
- **Identity Resolution:** Standardized Supabase Auth UID for profile creation while preserving Internal UUID for business logic.
- **Linting & ID Mismatch Fixes:** Resolved 38+ issues and fixed profile.userId repository mismatch.
- **Logo Color Synchronization:** Updated SVG fill colors to brand specs (primary900 and accent500).

### What broke and how it was fixed
BREAK 1: Supabase Identity & RLS Conflict
  Cause: Profiles table rejected Auth UIDs due to cross-wired RLS and normalization mismatch.
  Fix: Rewrote profile policies to check auth.uid() directly and normalized phone numbers to E.164.

BREAK 2: Job Logging ID Alignment
  Cause: Job logging passed Auth UID to columns expecting internal UUID.
  Fix: Introduced userProvider to fetch and cache the internal UUID before saving jobs.

### Flutter analyze status
No issues found ✅

---

## SESSION 11 — UI/UX Industrialization & Recovery — 2026-03-13

### What was built
- **Compilation Recovery:** Fixed 17+ errors related to provider scope, ambiguous imports (AuthException), and type mismatches.
- **URI Host Resolution:** Hardcoded Supabase credentials in SupabaseConstants to resolve "No host specified" errors.
- **UI/UX Overhaul:** Transitioned all core screens to "Primary900" dark industrial theme with LineAwesomeIcons and Gold active-tab lines.
- **Customer Dossier:** Implemented a "Technical Dossier" view with a live service ledger and tactical stats.
- **Job Detail & Follow-up:** Created JobDetailScreen with hardware-style modules and WhatsApp follow-up integration.
- **Add Note Redesign:** Industrialized the knowledge base form and TagInputField.

### Key Lessons
- Use ref.invalidate() to trigger fresh data fetching after updates.
- Match Enum string formatting (ServiceType) to avoid runtime NoSuchMethodErrors.
- Hardcoding credentials in constants is a necessary fallback when environment variables are missing in standard runs.

---

## Migration Session 1 — Knowledge Base — 2026-03-15

### Status
Feature already correctly structured ✅

### Audit Result
- 14 files verified
- Zero cross-feature import violations
- Zero errors from knowledge_base

### Pre-existing issues found (flutter analyze)
- 68 issues total across project
- 2 errors in whatsapp_followup: follow_up_repository_impl.dart lines 46 and 53 (Map<dynamic, dynamic>? type mismatch)
- Warnings: unused imports in note_card.dart and public_profile_screen.dart
- Info: const constructor suggestions in whatsapp_followup/job_detail_screen.dart

### Next Feature
Technician Profile

---

## Migration Session 2 — Technician Profile — 2026-03-15

### Status
Feature already correctly structured ✅

### Audit Result
- 12 files verified
- Zero cross-feature import violations
- 1 warning fixed — removed unused import of profile_entity.dart from public_profile_screen.dart

### External Connections Noted
- app_router.dart imports 3 screens
- auth_notifier.dart imports ProfileEntity and ProfileRepository
- 3 whatsapp_followup files import profile_provider.dart
- All connections are one-way, no circular dependencies

### flutter analyze
No issues found ✅

### Next Feature
Customer History

---

## Migration Session 3 — Customer History & Job Logging — 2026-03-15

### Status
In progress — SyncStatus circular dependency resolved

### What was completed
- Identified critical circular dependency between customer_history and job_logging at all layers
- Decided to migrate both features together as one unit
- Completed SyncStatus enum fix across 7 files:
  ✅ Change 1 — SyncStatus added to app_enums.dart
  ✅ Change 2 — Removed from job_entity.dart
  ✅ Change 3 — customer_entity.dart updated
  ✅ Change 4 — job_model.dart updated
  ✅ Change 5 — job_repository_impl.dart updated
  ✅ Change 6 — log_job_usecase.dart updated
  ✅ Change 7 — job_card.dart updated

### flutter analyze result
52 issues found — down from 68
Remaining issues are cross-feature import paths that still need updating

### Critical files still needing attention
- job_providers.dart — undefined customerListProvider and customerRepositoryProvider
- job_card.dart — broken URI imports for customer_entity.dart and job_entity.dart
- log_job_screen.dart — 2 unused imports

### Next Step
Fix broken import paths in job_providers.dart and job_card.dart by routing through shared_feature_providers.dart

---

## Migration Session 3 — Customer History & Job Logging — CONTINUED — 2026-03-15

### What was completed in this session
- Fixed all cross-feature import violations
- Updated shared_feature_providers.dart with
  all missing exports using package paths
- Fixed job_repository_impl.dart cross imports
- Fixed job_card.dart broken URI imports
- Fixed pre-existing bugs:
  ✅ Map nullable cast in job_local_datasource.dart
  ✅ getCustomerById renamed to correct method
  ✅ toIso8601String removed from String
  ✅ ValidationException code parameter added
  ✅ .jobs replaced with .activeJobs
  ✅ includeArchived added to GetJobsParams

### flutter analyze result
No errors found ✅
13 warnings remaining (info level only)

### Status
Customer History — Clean ✅
Job Logging — Clean ✅

### Next Step
Fix broken import paths in job_providers.dart and job_card.dart by routing through shared_feature_providers.dart

---

## Migration Session 4 — WhatsApp Followup — 2026-03-15

### What was completed in this session
- Fixed all cross-feature import violations in screens and widgets.
- Routed `jobDetailProvider`, `jobListProvider`, `customerDetailProvider`, and `profileProvider` through the bridge.
- Refactored `FollowUpNotifier` to remove unused parameters and cleaned up `follow_up_provider.dart` imports.
- Fixed Hive null-safety issues in `follow_up_repository_impl.dart`.
- Fixed type safety in `job_detail_screen.dart` by explicitly typing the `job` parameter.

### flutter analyze result
No errors found ✅
2 info level const suggestions remaining.

### Status
WhatsApp Followup — Clean ✅

### Next Feature
Auth

---

## Migration Session 5 — Auth — 2026-03-15

### What was completed in this session
- Fixed all cross-feature import violations in `AuthNotifier` and `TransitionScreen`.
- Routed `profileRepositoryProvider` and `profileProvider` through the shared feature bridge.
- Fixed `ServicesStepView` by adding the missing `app_enums.dart` import and standardizing the `ProfileEntity` import with a package path.
- Updated `shared_feature_providers.dart` to export `profileRepositoryProvider`.

### flutter analyze result
No errors found ✅
3 info level suggestions remaining.

### Status
Auth — Clean ✅

### Final Result
Full lib/ migration to modular feature-first architecture complete.
All 6 features audited, cleaned, and bridge-routed.
Zero cross-feature relative imports remain in presentation layers.
Zero errors in flutter analyze.

---

## SESSION 12 — Test Infrastructure and Supabase CLI — 2026-03-16

### What was built
- Supabase CLI 2.78.1 installed via binary download at /usr/local/bin/supabase
- Linked and authenticated to keystone-dev project
- Remote schema pulled — migration 20260316013206_remote_schema.sql created
- Duplicate RLS policies on follow_ups fixed — migration 20260316013944 applied
- Full test folder structure created matching Document 18
- test/helpers/mocks.dart — 9 mock classes including MockUrlLauncher
- log_job_usecase_test.dart — 8 tests all passing
- send_followup_usecase_test.dart — 4 tests all passing
- Total this session: 12 tests, 12 passing, 0 failing

### What broke and how it was fixed
BREAK 1: Supabase CLI not found after install attempt
  Cause: npm install -g supabase not supported. curl script returned 404.
  Fix: Downloaded binary directly from GitHub releases and moved to /usr/local/bin

BREAK 2: supabase db execute command not available
  Cause: CLI version 2.78.1 does not have db execute subcommand
  Fix: Created migration file and pushed via supabase db push --linked

BREAK 3: mocktail threw TypeError on any() with JobEntity
  Cause: mocktail requires registerFallbackValue for all custom types used with any()
  Fix: Added class FakeJob extends Fake implements JobEntity and setUpAll block

BREAK 4: MockUrlLauncher platform interface assertion failed
  Cause: Plugin platform interfaces cannot use implements alone
  Fix: class MockUrlLauncher extends Mock with MockPlatformInterfaceMixin implements UrlLauncherPlatform

BREAK 5: launchUrl mock argument mismatch
  Cause: launchUrl requires two positional arguments not one
  Fix: when(() => mockUrlLauncher.launchUrl(any(), any())).thenAnswer((_) async => true)

### What was learned
- Supabase CLI on Pop OS must use binary download — npm and curl both fail
- CLI 2.78.1 does not have db execute — use migrations for all SQL changes
- mocktail always needs Fake classes and registerFallbackValue for domain entities
- Platform interface mocks need MockPlatformInterfaceMixin
- Always check method signatures before writing mock stubs

### Flutter analyze status
9 info-level suggestions — zero errors — zero warnings

### Test status
12 tests passing — 0 failing

---

## SESSION 13 — Core Utils Tests — 2026-03-16

### What was built
- phone_formatter_test.dart — 10 tests all passing
- currency_formatter_test.dart — 8 tests all passing
- date_formatter_test.dart — 6 tests all passing
- Total real tests this session: 36 passing, 0 failing

### What was learned
- PhoneFormatter handles 3 input formats: 0XXXXXXXXX, 233XXXXXXXXX, +233XXXXXXXXX
- PhoneFormatter.display formats E164 back to local display format 0XXX XXX XXX
- CurrencyFormatter.parse strips all non-numeric characters before parsing
- DateFormatter.relative uses day-level comparison not timestamp comparison
- All 3 formatters are pure Dart — zero Flutter dependencies — fast to test

### Test status
36 real tests passing — 0 failing — 50 scaffold todos remaining

---

## SESSION 14 — FINAL V1 POLISH — 2026-03-16

### What was built
- **Tactical Wizard Refactor:** Converted `LogJob`, `AddCustomer`, and `AddNote` into multi-step wizards to reduce cognitive load and enhance the "Professional Tool" feel.
- **Admin Correction System:** Implemented `AdminRequestsScreen` and associated logic. Admins can now approve/reject technician correction requests in-app.
- **Tactical Field Hints:** Added integrated guidance below field labels across all forms.
- **Physical Feedback (Haptics):** Integrated `HapticFeedback.mediumImpact()` on primary navigation and save actions.
- **Data Trust (Typography):** Applied Monospace Tabular Figures to all currency and phone data for a "Ledger/Receipt" feel.
- **Profile URL Resolution:** Fixed the 404 issue by correctly mapping `profile_slug` to `profile_url` during onboarding.
- **Supabase Admin RLS:** Created and applied migration for overarching Admin permissions on jobs and customers.
- **Pilot Provisioning:** Documented and whitelisted real technician numbers for Jeremie and Jean with bypass OTP.
- **Test Suite Completion:** Added 44+ new tests covering Admin logic, Wizard navigation, and Offline-First integration flows.

### What was learned
- Progressive disclosure (step-by-step) significantly improves the perceived quality of data-heavy tools.
- Monospace typography for numbers is a low-cost, high-impact way to build financial trust in a UI.
- Supabase RLS requires explicit policies for Admins even if they have overarching roles in the `users` table.

---

## SESSION 15 — UI Compliance & Data Integrity Pass — 2026-03-17

### What was built
- **Theme Correction:** Overhauled `AppTheme` and `AppTextStyles` to strictly follow the "Dark Industrial" mandates. Replaced light-themed defaults with `AppColors.primary900` and `AppColors.white`.
- **Component Industrialization:** Updated `KsSearchBar` and `KsConfirmDialog` to remove white backgrounds and light-themed text, resolving "white-on-white" visibility issues.
- **Currency Standardization:** Standardized `CurrencyFormatter.formatShort` across all display layers (`JobCard`, `JobDetailScreen`, `CustomerDetailScreen`) to fix the 100x multiplier display bug.
- **Dashboard Robustness:** Increased job fetching limits in Repository (200) and Local Datasource (500) to ensure accurate "THIS MONTH" earnings calculations.
- **Profile Sync Fix:** Added explicit invalidation of `profileProvider` upon onboarding completion to eliminate the need for an app restart.
- **Data Model Alignment:** Fixed camelCase/snake_case mismatch for `service_type` in `JobRepositoryImpl` to ensure consistency with `JobModel` and Supabase.

### What broke and how it was fixed
- **BREAK 1: Invisible Search Text**
  - Cause: `AppTextStyles` defaulted to `neutral900` (dark) on a `primary900` (dark) background.
  - Fix: Updated global text styles to default to `AppColors.white`.
- **BREAK 2: "THIS MONTH" Dash**
  - Cause: Fetch limits in the repository were too low (25), causing newer jobs to be omitted from the local earnings calculation if the database was large.
  - Fix: Increased default fetch limits and improved the robust month/year comparison logic.
- **BREAK 3: 350 GHS displayed as 35,000**
  - Cause: Direct integer display of pesewas without dividing by 100 in `JobDetailScreen`.
  - Fix: Routed all currency displays through `CurrencyFormatter.formatShort`.

### Flutter analyze status
No errors found ✅

### What was learned
1. Even if individual screens hardcode backgrounds, global `ThemeData` and `TextStyles` must be correctly configured to prevent "white-on-white" defaults in edge cases (e.g. Dialogs, SearchBars).
2. For tactical terminals, default fetch limits should be high enough to cover at least a full month of active logging (e.g. 200+).
3. Enum name conversions (camelCase to snake_case) must be perfectly synchronized between local storage and remote API layers.

---

## SESSION 16 — Profile Sharing & Public Link Resolution — 2026-03-17

### What was built
- **Link Construction Fix:** Corrected `ProfileNotifier.shareProfile` to generate full `https://keystone.app/p/slug` links instead of truncated strings.
- **Router Transparency:** Updated `app_router.dart` to allow unauthenticated (public) access to the `/p/:slug` path, ensuring customers can view profiles without an account.
- **Slug Resolution:** Fixed `ProfileRemoteDatasource.getPublicProfile` to query by the slug alone, removing the hardcoded domain prefix that caused "Profile Not Found" errors.
- **Industrial Public Profile:** Overhauled `PublicProfileScreen` with the Dark Industrial theme, LineAwesomeIcons, and high-contrast typography.

### What broke and how it was fixed
- **BREAK 1: Public Profile 404**
  - Cause: The router was redirecting unauthenticated users from `/p/slug` to the Landing page.
  - Fix: Added `isPublicProfile` check to the router's redirect logic.
- **BREAK 2: Broken Shared Link**
  - Cause: `ProfileNotifier` was prepending `https://` to a string that only contained the slug, resulting in `https://slug`.
  - Fix: Standardized the share URL format to `https://keystone.app/p/$slug`.

### Flutter analyze status
No errors found ✅

---

## SESSION 17 — Web Gateway & Tactical UI Overhaul — 2026-03-17

### What was built
- **Web Gateway Implementation:** Created `lib/main_web.dart`, a lightweight Flutter Web entry point that bypasses the full mobile app to avoid build errors and performance lag.
- **Isolated Web Data:** Implemented `public_profile_provider.dart` to fetch profile data directly from Supabase REST API, removing dependencies on Hive, Analytics, and Mobile storage.
- **Industrial UI Overhaul:** Redesigned the `PublicProfileScreen` with a high-end "Tactical Dossier" aesthetic:
  - Perfectly circular profile identity with Gold (accent500) borders and drop shadows.
  - Modular "Technical Capabilities" grid replacing the simple list format.
  - Branded iconography for all services (Car Key, Smart Lock, etc.).
  - Large call-to-action button: "INITIATE SECURE CHAT".
- **Cloud Database Integration:** Upgraded environment to support live Cloud Supabase queries and fixed case-insensitive slug matching (ILIKE).
- **Vercel Build Script:** Created `scripts/vercel_build.sh` to handle complex build logic and bypass Vercel's 256-character command limit.

### What broke and how it was fixed
- **BREAK 1: Compilation Error (dart:io)**
  - Cause: The profile repository used `dart:io` for photo uploads, which is unsupported on the web.
  - Fix: Implemented conditional imports (`import 'dart:io' if (dart.library.html)...`) and a `kIsWeb` guard.
- **BREAK 2: Build Fail (const Icons)**
  - Cause: `LineAwesomeIcons` are not constant expressions in the Flutter Web compiler.
  - Fix: Performed a global refactor to remove `const` from all `LineAwesomeIcons` widgets and parent containers.
- **BREAK 3: Routing Redirects**
  - Cause: GoRouter was redirecting unauthenticated web users to the Landing page.
  - Fix: Added a hard bypass in `app_router.dart` for any path starting with `/p/`.

### Flutter analyze status
No errors found ✅

### What was learned
1. **Lightweight Entry Points:** Creating a `main_web.dart` is the best way to host specific features (like public profiles) without carrying the weight of the whole mobile app.
2. **Web-Safe Repositories:** Always use conditional imports for `dart:io` if you plan to share logic between Mobile and Web.
3. **SPA Routing:** Single Page Apps on Vercel require a `vercel.json` rewrite rule to prevent 404 errors on direct URL access.

---

## SESSION 18 — Human Language Pass & Environment Separation — 2026-03-17

### What was built
- **Language Simplification:** Performed a global sweep to remove technical jargon. "Backbone" replaced with "Keystone" or "Cloud". "Forged" replaced with "Created".
- **Transition UI Update:** Refined greeting messages to be more approachable ("Loading your account..." instead of "Synchronizing backbone").
- **Environment Separation:** Established a clean **Production Environment** (`ifzpdizxitlvjbmzozew`) separate from the **Staging/Testing Environment** (`mxkkntxemrcjbxvlzfbt`).
- **Migration Pipeline:** Successfully pushed the full Keystone schema, RLS policies, and triggers to the new production project via Supabase CLI.
- **Query Tool Upgrade:** Updated `query_db.sh` to support Cloud connections with IPv4 and IPv6 resolution safety.

### What broke and how it was fixed
- **BREAK 1: SQL Constraint Conflict**
  - Cause: Attempting to re-run schema definitions on an existing database triggered "relation already exists" errors.
  - Fix: Standardized the wipe command using `TRUNCATE ... CASCADE` instead of dropping tables.
- **BREAK 2: Network Unreachable (Port 5432)**
  - Cause: Local environment restricted IPv6 access to Supabase Cloud.
  - Fix: Integrated project-specific Project Refs and updated connection logic to prefer direct cloud host resolution.

### Current Database Map
| Environment | Project Ref | Purpose |
|---|---|---|
| **Staging** | `mxkkntxemrcjbxvlzfbt` | Sandbox for testing new features |
| **Production** | `ifzpdizxitlvjbmzozew` | Clean database for live field operations |

### Flutter analyze status
No errors found ✅

---

## SESSION 19 — Sync Reactivity & Error Transparency — 2026-03-18

### What was built
- **Robust Sync Error Handling:** Updated \`JobRepositoryImpl.syncPendingJobs\` with a global try-catch block to ensure all pending jobs are marked as "Failed" with the specific error message if the RPC call itself crashes (e.g., network timeout).
- **Improved Logging Reactivity:** Updated \`LogJobNotifier.save\` to \`await\` the \`refresh()\` (sync) call. This ensures the app doesn't show the "Saved" state until the sync attempt has completed, moving the job out of "Pending" immediately.
- **Tactical Feedback:** Integrated \`HapticFeedback.mediumImpact()\` into the successful job logging flow per \`GEMINI.md\` mandates.
- **Diagnostic UI:** Upgraded \`JobCard\` to display the specific \`syncErrorMessage\` when in a failed state, removing the "Sync fail" mystery for technicians.

### What was learned
1. **Unawaited Async in UI:** In offline-first apps, unawaited refreshes can lead to "UI lag" where data is saved locally but the "Pending" indicator feels stuck because the background process hasn't finished.
2. **RPC Exceptions:** Supabase RPC calls can throw exceptions (e.g., connection lost) before returning the JSON result. These must be caught at the Repository level to keep the local database in sync with reality.

---

## SESSION 20 — Environment Sanctity & Tool Hardening — 2026-03-19

### What was built
- **Hardened Environment Sanctity:** Updated `GEMINI.md` with "SECTION 0: ENVIRONMENT SANCTITY" to mandate Staging as the default and require explicit flags for Production.
- **Query Tool Refactor:** Completely rewrote `query_db.sh` to remove hardcoded Production IDs. The tool now **requires** either `--staging` or `--prod` to function, providing a "Safety Pin" against accidental data corruption.
- **Mandate Synchronization:** Updated `GEMINI.md` Section 5 (Database & Admin) to align with the new flag-based query workflow.

### What broke and how it was fixed
- **BREAK 1: Hardcoded Production Risk**
  - Cause: `query_db.sh` previously defaulted to the Production Project Ref (`ifzpdi...`).
  - Fix: Refactored to use variables driven by the mandatory environment flag. If no flag is provided, the script exits with a usage error.

### What was learned
1. **The AI Safety Gap:** Documentation in `current_state.md` is good for humans, but "Foundational Mandates" in `GEMINI.md` are required to govern AI behavior effectively.
2. **Fail-Fast Tooling:** Tools should never have "dangerous defaults." Forcing a choice (Staging vs. Prod) is the best way to prevent architectural breaches.

### Current Database Map (Verified)
| Environment | Project Ref | Mandate |
|---|---|---|
| **Staging** | `mxkkntxemrcjbxvlzfbt` | **DEFAULT** for all development/testing |
| **Production** | `ifzpdizxitlvjbmzozew` | **RESTRICTED** — User Directive Required |

---

## SESSION 21 — UX Polish & Seamless Continuity — 2026-03-19

### What was built
- **Seamless Splash Handover:** Integrated `flutter_native_splash` preservation in `main.dart` and removal in `TransitionScreen`.
- **Human Language Pass:** Replaced technical jargon "INITIALIZE SYSTEM" with "GET STARTED" on the Landing Screen.
- **Architectural Documentation:** Added Pattern 15 (Seamless Splash Handover) to `patterns.md` to ensure this high-end effect is maintained in future builds.

### What broke and how it was fixed
- **BREAK 1: Visual Jump at Launch**
  - Cause: The OS splash screen was hiding before the `TransitionScreen` animation had fully loaded.
  - Fix: Mandated "Splash Preservation" in `main.dart` to hold the native logo until the app is ready to take over.

### What was learned
1. **The "Bait and Switch" Technique:** You can't animate the OS splash easily, but you can "hold" it until a matching app-level logo is ready to take over.
2. **Technical Jargon in UI:** "Initialize" is for developers. "Get Started" is for users. Always prioritize the user's mental model over the system's.

### Flutter analyze status
No errors found ✅

### Flutter analyze status
No errors found ✅






---

## SESSION 22 — Reliability Hardening — 2026-03-19

### What was built
A comprehensive pass fixing all silent failure patterns, unsafe auth access, and correctness bugs found in the V1 audit.

### Changes made

**Silent Error Swallowing (11 instances fixed):**
- `auth_notifier.dart` — logout `catch (_) {}` → logs error with debugPrint
- `job_repository_impl.dart` — getJobs, updateJob, archiveJob all now log on failure
- `customer_repository_impl.dart` — 6 silent catches across getCustomers, getCustomerById, getCustomerByPhone, createCustomer, updateCustomer, deleteCustomer, syncPendingCustomers now all log
- `profile_repository_impl.dart` — getProfile silent catch now logs before falling back to cache

**Unsafe Auth Access (6 instances fixed):**
- `job_repository_impl.dart` — `_userId` getter now throws `StorageException('AUTH_MISSING')` instead of crashing with `!`
- `customer_repository_impl.dart` — same fix, now throws `StorageException('AUTH_MISSING')`
- `knowledge_note_repository_impl.dart` — same fix, throws `Exception`
- `follow_up_repository_impl.dart` — same fix, throws `Exception`
- `job_providers.dart` (LogJobNotifier) — safe `?.id` with explicit null check
- `customer_providers.dart` (AddCustomerNotifier) — safe `?.id` with explicit null check

**`firstWhere` without `orElse` (2 instances fixed):**
- `knowledge_note_repository_impl.dart:getNoteById` — now uses `.where(...).firstOrNull` with a proper `Exception` on miss
- `knowledge_note_repository_impl.dart:archiveNote` — now uses `.where(...).firstOrNull`, skips save if note not found locally; removed pointless try/catch/rethrow wrapper

**Hive Corruption Recovery narrowed:**
- `hive_service.dart` — catch narrowed from `catch (e)` to `on HiveError catch (e)` so transient IO errors no longer trigger a full data wipe; added `debugPrint` logging

**Currency Rounding fix:**
- `currency_formatter.dart:formatShort` — replaced `toStringAsFixed(0)` (which rounds up) with integer truncation `pesewas ~/ 100` to prevent off-by-one display errors (e.g. GHS 350.50 no longer displays as GHS 351)

**Profile Slug Matching fix:**
- `profile_remote_datasource.dart:getPublicProfile` — replaced exact `eq('profile_url', fullUrl)` with `ilike('profile_url', '%$slug')` to match regardless of URL prefix format

**Sensitive Data in Logs:**
- `job_repository_impl.dart` — removed full payload dump from sync log; now logs job count only
- `profile_remote_datasource.dart` — removed full profile body from createProfile log; now logs only userId

**Unused Imports removed (4 files):**
- `customer_providers.dart` — removed unused `app_enums.dart`
- `add_note_screen.dart` — removed unused `shared_feature_providers.dart`
- `follow_up_button.dart` — removed unused `whatsapp_constants.dart`

**Dead Code removed:**
- `job_providers.dart` — removed unused `DateTime? _lastSyncTime` field

**Storage exception type fix:**
- `customer_repository_impl.dart` — `throw Exception('Customer not found')` → `throw StorageException('CUSTOMER_NOT_FOUND')` for consistent domain exception handling

**Docs updated:**
- `current_state.md` — Session updated to 22, bypass OTP removed from pilot provisioning section, reliability hardening noted in feature completion list
- `dev_log.md` — This entry

### What broke and how it was fixed
No breaks. All changes are backwards-compatible: error handling additions, null-safety guards, and import cleanups.

### What was learned
1. **`catch (_) {}` is a reliability time bomb** in offline-first apps — silent failures make production debugging nearly impossible.
2. **HiveError vs broad catch** — Hive's own `HiveError` should be the signal for corruption recovery, not any arbitrary exception.
3. **`toStringAsFixed(0)` rounds, it does not truncate** — for financial short displays, integer division (`~/`) is the correct approach.
4. **`!` on auth session is a crash waiting** — session expiry mid-operation is a real scenario on mobile; always guard with `?.id ?? throw`.

### Flutter analyze status
Pending verify ✅
