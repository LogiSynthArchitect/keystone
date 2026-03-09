# KEYSTONE DEV LOG
Running record of what was built, what broke, and what was learned.
Append-only. Never edited — only added to.

---

## SESSION 1 — 2026-03-09

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

---

## SESSION 2 — 2026-03-09

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

### What comes next
- Phase 2 — Domain entities (Step 09)
- All 6 entities: User, Profile, Customer, Job, KnowledgeNote, FollowUp
- Then domain repository interfaces (Step 10)

### Flutter analyze status
No issues found ✅

### Device test
App boots on physical Android device ✅
Shows "Jobs — coming soon" on neutral050 background ✅

---

## SESSION 2 — 2026-03-09

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

BREAK 2: GitHub PAT accidentally posted publicly
  Fix: token deleted immediately, new token generated, credential.helper store configured
  Learning: never paste tokens in chat — use credential.helper store from the start

### What was learned
- Supabase SQL editor runs sections independently — run in order from Document 12.8
- Git credential.helper store saves token permanently after first entry
- Router placeholder screens let us verify routing before building real screens

### Flutter analyze status
No issues found ✅

### Device test
App boots on physical Android device ✅

---

## SESSION 3 — 2026-03-09

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

## SESSION 4 — 2026-03-09

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
