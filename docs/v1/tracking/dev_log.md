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

---

## SESSION 5 — 2026-03-10

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

## SESSION 6 — 2026-03-10

### What was built
- Diagnosed and fixed 3 auth flow bugs that were breaking the core user journey

### What broke and how it was fixed

BREAK 1: OTP verify had a double-navigation race condition
  File: lib/features/auth/presentation/screens/otp_verify_screen.dart
  Cause: _onVerify() manually called context.go() AND invalidated authStateProvider,
         which triggered the router's _RouterNotifier to also navigate simultaneously.
         Two navigations firing at once caused unpredictable behaviour.
  Fix: Removed all manual context.go() calls from _onVerify(). Now only calls
       ref.invalidate(authStateProvider) and lets the router redirect handle navigation.
  Also removed unused route_names.dart import. Kept go_router import for context.pop().

BREAK 2: Onboarding completed but router immediately bounced user back to onboarding
  File: lib/features/auth/presentation/screens/onboarding_screen.dart
  Cause: After saving profile, screen called context.go(RouteNames.jobs) but never
         invalidated authStateProvider. Router still had hasProfile=false in its state,
         so the redirect rule (_isAuthenticated && !_hasProfile → onboarding) fired
         and sent the user straight back.
  Fix: Replaced context.go(RouteNames.jobs) with ref.invalidate(authStateProvider).
       Router now re-reads auth state, sees hasProfile=true, and navigates to /jobs.
  Also removed unused go_router and route_names imports, added auth_provider import.

BREAK 3: Sign out could crash with null error before redirect fired
  File: lib/features/technician_profile/data/repositories/profile_repository_impl.dart
  Cause: String get _userId => _supabase.auth.currentUser!.id used bang operator.
         After signOut(), currentUser becomes null. Any profileProvider rebuild
         during the sign-out window would throw a null crash before the router
         could redirect away from the profile screen.
  Fix: Changed to _supabase.auth.currentUser?.id ?? '' — safe null handling.

### Flutter analyze status
No issues found ✅

### What comes next
- Test the full auth flow on physical device:
  Phone → OTP → Onboarding → Jobs → Profile → Sign out → Phone entry
- If all passing: Phase 9 remaining work (PublicProfileScreen, photo upload)
- Then Phase 10: Polish and production readiness

---

## SESSION 6 CONTINUED — 2026-03-10

### What was built
- Added structured debug logging to auth flow
- All KS:AUTH and KS:AUTH_STATE log lines now print to terminal during testing
- Logging covers: requestOtp, verifyOtp, getCurrentUser, createUser, signOut, onAuthStateChange, profile check

### What broke and how it was fixed
BREAK: debugPrint not available in AuthRemoteDatasource
  Cause: missing flutter/foundation.dart import
  Fix: full rewrite of auth_remote_datasource.dart with import added

BREAK: string concatenation warnings in auth_provider.dart
  Cause: used + operator instead of string interpolation in debugPrint calls
  Fix: full rewrite of auth_provider.dart using interpolation throughout

### Key learning
- Surgical patching with bash heredoc is unreliable — bash interprets $, !, and em-dashes
- Full file rewrites using python3 << PYEOF are the correct approach for every file change
- Never use inline python3 -c with multi-line strings containing special characters

### Flutter analyze status
No issues found

### What comes next
- Run app with two terminals
- Terminal 1: bash run.sh
- Terminal 2: flutter logs | grep KS:
- Test full auth flow and paste Terminal 2 output to diagnose any remaining issues

---

## SESSION 6 CONTINUED — 2026-03-10

### What was built
- Added structured debug logging to auth flow
- All KS:AUTH and KS:AUTH_STATE log lines now print to terminal during testing
- Logging covers: requestOtp, verifyOtp, getCurrentUser, createUser, signOut, onAuthStateChange, profile check

### What broke and how it was fixed
BREAK: debugPrint not available in AuthRemoteDatasource
  Cause: missing flutter/foundation.dart import
  Fix: full rewrite of auth_remote_datasource.dart with import added

BREAK: string concatenation warnings in auth_provider.dart
  Cause: used + operator instead of string interpolation in debugPrint calls
  Fix: full rewrite of auth_provider.dart using interpolation throughout

### Key learning
- Surgical patching with bash heredoc is unreliable — bash interprets $, !, and em-dashes
- Full file rewrites using python3 << PYEOF are the correct approach for every file change
- Never use inline python3 -c with multi-line strings containing special characters

### Flutter analyze status
No issues found

### What comes next
- Run app with two terminals
- Terminal 1: bash run.sh
- Terminal 2: flutter logs | grep KS:
- Test full auth flow and paste Terminal 2 output to diagnose any remaining issues

---

## SESSION 6 FINAL — 2026-03-10

### What was built
- Full auth flow working end to end on physical device
- Phone entry → OTP → Jobs dashboard
- Jobs dashboard → Profile → Sign out → Phone entry
- Clean log output — no loops, no crashes

### What broke and how it was fixed

BREAK 1: OTP verify had double-navigation race condition
  File: otp_verify_screen.dart
  Cause: screen manually called context.go() AND invalidated authStateProvider
         simultaneously — two navigations racing each other
  Fix: removed all manual context.go() calls — router redirect handles navigation

BREAK 2: Onboarding bounced user back to onboarding after saving profile
  File: onboarding_screen.dart
  Cause: context.go(RouteNames.jobs) called but authStateProvider never invalidated
         so router still saw hasProfile=false and redirected back
  Fix: replaced context.go() with ref.invalidate(authStateProvider)

BREAK 3: Profile screen crashed on sign out
  File: profile_repository_impl.dart
  Cause: _userId getter used bang operator _supabase.auth.currentUser!.id
         after signOut() currentUser becomes null — null crash before router redirect
  Fix: changed to _supabase.auth.currentUser?.id ?? '' safe null handling

BREAK 4: Infinite rebuild loop on initialSession event
  File: auth_provider.dart
  Cause: onAuthStateChange listener called ref.invalidateSelf() on every event
         including initialSession. Supabase replays current auth state to every
         new listener. So every invalidateSelf() created a new notifier, new listener,
         new initialSession event, new invalidateSelf() — infinite loop
  Fix: filtered to only react to initialSession events — but signedIn still looped

BREAK 5: Infinite rebuild loop on signedIn event
  File: auth_provider.dart
  Cause: same root cause as BREAK 4 — signedIn also replayed to new listeners
         Every invalidateSelf() → new build() → new listener → signedIn replayed
  Fix attempted: filter signedIn too — but pattern is fundamentally broken

BREAK 6: Root cause identified and fixed — onAuthStateChange listener removed entirely
  File: auth_provider.dart
  Cause: The fundamental problem is that Supabase onAuthStateChange replays
         current auth state to every new subscriber. Since Riverpod creates a new
         notifier (and new listener) on every invalidateSelf(), any event that
         triggers invalidateSelf() inside the listener causes an infinite loop.
         This is not fixable by filtering events — the architecture is wrong.
  Fix: Removed onAuthStateChange listener completely from AuthNotifier.build()
       Added explicit refresh() method — called once from otp_verify_screen after
       successful OTP verify
       signOut() already calls invalidateSelf() directly — no listener needed
       Result: authStateProvider only rebuilds when explicitly told to

### What was learned
1. Supabase onAuthStateChange replays current state to every new subscriber
   Never call invalidateSelf() inside an onAuthStateChange listener — infinite loop
   Always trigger auth state rebuilds explicitly from the call site instead

2. Surgical patching with bash heredoc is unreliable
   Bash interprets $, !, em-dashes inside heredocs
   Always use python3 << PYEOF for file writes
   Always do full file rewrites — never surgical string replacement

3. ref.watch() inside AsyncNotifier.build() causes rebuild loops
   Use ref.read() for providers that do not change (like supabaseClientProvider)

4. Router redirect depends on authStateProvider — not profileProvider
   Invalidating profileProvider alone does not trigger router redirect
   Must invalidate authStateProvider to make router re-evaluate redirect rules

5. Two sources of truth = bugs
   Never force state manually (e.g. forceProfileComplete())
   Always derive state from database — invalidate and let provider refetch

### Flutter analyze status
No issues found

### Device test
App boots → straight to jobs (session persisted) ✅
Sign out → phone entry screen ✅
Phone entry → OTP → jobs dashboard ✅
Full auth flow clean with no loops ✅

### What comes next
- Phase 9 remaining: PublicProfileScreen, photo upload flow
- Phase 10: Polish and production readiness
- Checkpoint 4: Full smoke test

---

## SESSION 7 — 2026-03-10

### What was built
- Phase 9 complete: Technician Profile feature
- PublicProfileScreen — displays profile publicly via /p/:slug route, no auth required
- Photo upload flow wired into EditProfileScreen — image picker, upload to Supabase storage, pending URL saved on profile update
- publicProfileProvider added to profile_provider.dart using FutureProvider.family
- Router updated — replaced stub with real PublicProfileScreen
- Debug logging added to ProfileNotifier (load, update, uploadPhoto)

### What broke and how it was fixed
No breaks this session — clean build first attempt

### Flutter analyze status
No issues found

### Device test
- To be tested: edit profile photo upload
- To be tested: public profile via share link
- To be tested: WhatsApp CTA on public profile

### What comes next
- Phase 10: Polish and production readiness (Steps 63-70)
  - Step 63: Offline banner animations
  - Step 64: Skeleton loaders on all list screens
  - Step 65: Pull-to-refresh on all list screens
  - Step 66: Unsaved changes dialogs on all edit screens
  - Step 67: Analytics events
  - Step 68: Error boundary in app.dart
  - Step 69: app_events Supabase table
  - Step 70: Pre-release checklist
- Checkpoint 4: Full smoke test on physical device

---

## SESSION 7 CONTINUED — Phase 10 complete

### What was built
- Step 66: Unsaved changes dialogs — PopScope added to all 4 edit screens (log_job, add_note, add_customer, edit_profile)
- Step 67: Analytics — KsAnalytics helper created, fire-and-forget events wired into job_logged, note_saved, customer_added, profile_shared
- Step 68: Error boundary — _ErrorBoundary widget wraps entire app, catches Flutter errors, shows restart screen
- Step 69: app_events Supabase table created with RLS — authenticated users can insert and select own events
- Steps 63-65 were already complete from previous phases (offline banner, skeleton loaders, pull-to-refresh)

### Lessons
- PopScope.onPopInvokedWithResult — capture Navigator.of(context) BEFORE the await to avoid use_build_context_synchronously warning
- Analytics must never throw — always wrap in try/catch, fire and forget
- AppColors.error700 does not exist — use error600

### Flutter analyze status
No issues found

### Device test
- To be tested: unsaved changes dialog on back press
- To be tested: analytics events appearing in app_events table

### What comes next
- Checkpoint 4: Full smoke test on physical device — all 5 features + offline + sync
- Step 70: Pre-release checklist
- UI design and mockups phase (separate track)
- Domain registration: keystone.app

---

## SESSION 7 — Bug fix: photo upload

### What broke
Photo upload returning 403 Unauthorized from Supabase storage

### Root cause
storage_profile_photos_insert RLS policy was assigned to {public} role instead of {authenticated}
Authenticated users were being blocked by their own upload policy

### Fix
1. Dropped and recreated storage_profile_photos_insert with TO authenticated
2. Did same for storage_note_photos_insert
3. Added cache-busting timestamp to uploaded photo URL (?t=milliseconds)
   — Without this, NetworkImage shows cached old photo even after successful upload

### Lesson
Always check the roles column on storage RLS policies — {public} and {authenticated} are different
Supabase storage upsert needs both INSERT and UPDATE policies for overwriting existing files

### Device test
Photo upload — SUCCESS
New photo displays immediately after save — SUCCESS

---

## SESSION 7 — Checkpoint 4 complete

### Smoke test results
- Auth flow: PASS
- Log job online: PASS
- Log job offline + sync: PASS
- Add customer: PASS
- Add note: PASS
- Sign out / sign back in: PASS
- Photo upload: PASS
- Unsaved changes dialog: PASS

### Bugs fixed during checkpoint
1. Photo upload 403 — storage RLS policy was {public} not {authenticated}
2. Photo not updating — NetworkImage caches by URL — fixed with cache-busting timestamp
3. Unsaved changes dialog not showing — KsAppBar called Navigator.pop() directly bypassing PopScope
   Fix: changed to Navigator.maybePop() which respects PopScope.canPop
4. PopScope not intercepting Android back gesture — missing android:enableOnBackInvokedCallback="true" in manifest

### What comes next
- Step 70: Pre-release checklist
- Domain registration: keystone.app
- UI design and mockups phase
- Play Store submission prep

---

## SESSION 9 — App Icon & Splash Screen

### Goal
Design and implement the Keystone app icon and splash screen.

### Icon Design Process
- Concept: arch with keystone block at crown, keyhole inside keystone block
- Colors: navy blue (#1A237E) arch, gold (#F9A825) keystone, navy keyhole
- Used AI image generator (Gemini) iteratively to refine the design
- Key iterations:
  1. First attempt — key symbol too detailed, arch legs cut off
  2. Second attempt — keyhole cleaner, arch had proper base — best open arch version
  3. Tried solid arch — looked like a mailbox, lost arch character
  4. Switched to white arch on navy background — strong but generator kept adding rounded square container
  5. Went back to isolated logo on white background approach
  6. Final logo saved as logos.png (1248x1248 RGBA) from Adobe Express

### Splash Screen — Long Journey
Iterations and lessons learned:

1. **Manual PNG approach** — placed logo PNG directly in drawable folder
   - Problem: Android bitmap tag scales image down no matter how large the PNG
   - Result: always small and sometimes blurry

2. **flutter_native_splash package** — correct tool for the job
   - Generates splash files for all Android densities automatically
   - Controls size through canvas proportion — logo size relative to canvas
   - CRITICAL LESSON: this package must be added, used to generate, then REMOVED
   - Reason: flutter_native_splash has its own build.gradle requiring AGP 8.7.0
   - AGP 8.7.0 cannot be downloaded on this network (dl.google.com blocked)
   - Project uses AGP 8.11.1 which is cached — conflict cannot be resolved
   - Workflow every time splash needs updating:
       1. flutter pub add dev:flutter_native_splash
       2. dart run flutter_native_splash:create --path=flutter_native_splash.yaml
       3. flutter pub remove flutter_native_splash
       4. run.sh

3. **SVG attempt** — tried using logo.svg thinking it was true vector
   - Problem: the SVG was just a wrapper around an embedded PNG (created by Inkscape)
   - rsvg-convert rendered it tiny because the embedded PNG was small
   - Lesson: always verify SVG is true vector paths, not embedded raster

4. **Final solution** — use logos.png (1248x1248) as source, render at exact dimensions
   - Canvas: 1080x1920 (standard phone screen)
   - Logo: 900x1300 (slightly taller than wide to show full arch with legs)
   - Logo centered on canvas
   - Result: clear, sharp, well proportioned splash screen

### Final Splash Dimensions
- Canvas: 1080 x 1920
- Logo: 900 x 1300
- Source: ~/Downloads/logos.png

### App Icon
- White background square canvas
- Logo centered with padding
- Generated all Android mipmap sizes from master 1024x1024

### Key Rules Learned
- flutter_native_splash: add → generate → remove (every time)
- SVG from Inkscape may contain embedded PNG — verify before using
- Control splash logo size through canvas proportion, not package parameters
- Never scale PNG above its source resolution — causes blur
- logos.png (1248x1248) is the master source for all icon/splash work

---

## SESSION 9 CONTINUED — KsLogo SVG Implementation

### Goal
Create a pixel-perfect programmatically controllable Flutter logo widget.

### The Long Journey

**Attempt 1 — CustomPainter from scratch**
- Drew arch, keystone, keyhole manually using cubic bezier curves
- Result: looked like a horseshoe — single continuous arch, not two separate arms
- Lesson: cannot guess path coordinates for a complex logo — need exact data

**Attempt 2 — Inkscape trace by color**
- Traced logos.png in Inkscape using color mode
- Problem: both arms and keyhole are same navy color — Inkscape merged them into one object
- Used Path → Break Apart to separate sub-paths
- Got 4 separate parts: left_arm, right_arm, keystone_block, keyhole
- Exported each as individual SVG

**Attempt 3 — flutter_svg with Stack positioning**
- Tried placing each SVG part in a Flutter Stack at calculated positions
- Problem: each exported SVG has its own coordinate system starting at 0,0
- Parts lost their original positions relative to each other
- Result: scattered, wrong positions

**Attempt 4 — Combined SVG with translate**
- Tried combining parts using SVG transform="translate(x,y)"
- Problem: mm vs px unit confusion caused parts to not render
- Multiple iterations, still not working

**Attempt 5 — svgpathtools analysis**
- Installed svgpathtools to analyze path coordinates
- Confirmed all parts start at 0,0 — no original position data preserved
- Tried calculating positions manually — keyhole still wrong

**The Breakthrough — Full combined SVG from Inkscape**
- Instead of combining parts manually, went back to Inkscape
- Selected all parts together and exported as one complete SVG
- This preserved the original coordinate relationships between all parts
- Result: perfect logo with all parts in exact correct positions

**Final Solution**
- Complete SVG with 4 named paths: keystone_block, keyhole, right_arm, left_arm
- Cleaned up SVG — removed style= attributes, kept only fill= attributes
- Each path has its own id for programmatic control
- Saved as: assets/logo/ks_logo_combined.svg
- KsLogo widget uses flutter_svg SvgPicture.asset to render it

### Key Lessons Learned
1. Never try to manually reassemble SVG parts that were exported individually
2. The correct workflow is: arrange all parts in Inkscape → export the whole thing as one SVG
3. Individual part exports lose their position context — useless for reassembly
4. flutter_svg renders SVG perfectly at any size — no blur, no scaling issues
5. Clean SVG = fill attributes only, no style= tags, named ids on each path

### What We Now Have
- ks_logo_combined.svg with 4 independently addressable paths
- Fully programmatic — colors changeable at runtime
- Scalable to any size with zero blur
- Ready for animations, theming, dark mode

### File Locations
- SVG: assets/logo/ks_logo_combined.svg
- Widget: lib/core/widgets/ks_logo.dart
- Parts data: assets/logo/parts_data.json (reference)
- Individual parts: assets/logo/left_arm.svg, right_arm.svg, keystone_block.svg, keyhole.svg

---

## SESSION 10 — Landing Screen & Font System

### Font System
- Added Barlow Semi Condensed full family (18 variants) to assets/fonts/
- Registered all weights (100-900) and italic variants in pubspec.yaml
- Replaced all GoogleFonts.inter() calls in app_text_styles.dart with
  TextStyle(fontFamily: 'BarlowSemiCondensed')
- Removed google_fonts import from app_text_styles.dart
- Rule: all text in app uses BarlowSemiCondensed, weight 600+ preferred

### Landing Screen — New Screen Created
File: lib/features/auth/presentation/screens/landing_screen.dart

Design concept: split screen
- Top 62%: off-white #FAFAF8 background, logo centered, text block
- Bottom 38%: deep navy #1A237E background, gold CTA button, sign in link

Layout (top to bottom):
- KsLogo 170px centered with fade+slide entrance animation
- Gold spaced label: LOCKSMITH MANAGEMENT (11px, weight 600, tracking 3.5)
- Keystone (54px, weight 800, navy)
- Subtitle: Built for Ghana's professional locksmiths (17px, weight 600, grey)
- Gold button: Get Started (navy bg bottom section, gold button)
- Sign in line: RichText — white70 + gold Sign in (weight 700)

Animations: staggered entrance via AnimationController 1400ms
- Logo: fade + slide up (0-50%)
- Text: fade in (30-65%)
- Button: fade in (60-100%)

Typography decisions:
- All weights 600+ only — no thin or regular weight text
- No underlines on links — use color contrast instead
- Two-tone RichText for "Already have an account? Sign in"

### Router Updates
- Added RouteNames.landing = '/'
- Initial location changed from phoneEntry to landing
- Redirect logic: unauthenticated users go to landing not phoneEntry
- Authenticated users bypass landing entirely → jobs dashboard

### Key Design Lessons
1. Split screen (light top / dark bottom) creates strong visual hierarchy
2. Gold accent on navy is the brand signature — use it for all CTAs
3. Never underline links in mobile — use color contrast
4. BarlowSemiCondensed at 800 weight is the hero font for this app
5. RichText for mixed-style inline text (no wrapping widgets needed)

---

## SESSION 10 CONTINUED — Phone Entry Screen Redesign

### Design
- Removed KsLogo and Keystone title — user already saw them on landing screen
- Icon badge: navy rounded square, gold mobile icon (28px) — establishes screen identity
- Split layout: off-white top / navy bottom — consistent with landing screen language
- Heading: 38px w800 navy, left-aligned — task-focused not brand moment
- Subtitle: 16px w600 grey
- Unified phone input: one seamless box, no divider between flag and number field
- Ghana flag SVG + +233 prefix left side, number input flows naturally right
- Gold check icon when number is valid, grey X when invalid
- Animated feedback banner: slides in from top, red for error, green for success, auto-dismisses after 4s
- Keyboard aware: navy bottom hides when keyboard opens, floating navy Continue button appears above keyboard instead

### Files changed
- lib/features/auth/presentation/screens/phone_entry_screen.dart — full rewrite
- assets/flags/gh.svg — Ghana flag downloaded from flagcdn.com
- pubspec.yaml — assets/flags/ registered

### Packages used
- flutter_svg — renders Ghana flag
- line_awesome_flutter — back arrow, mobile icon, check, X, error icons

### Key lessons
- Never use Row with BoxDecoration border to split a text field — it creates a visible divider
- For prefix + input in one box: use Padding widget for prefix, TextField with InputBorder.none for input
- hot reload does not re-run initState — LateInitializationError means you need full restart
- keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0 is reliable for keyboard detection

---

## SESSION 10 CONTINUED — OTP Verify Screen Redesign

### Design
- Same pattern as phone entry: off-white top / navy bottom
- Icon badge: navy square, gold shield icon (28px)
- Heading: "Verify your number" 38px w800
- Phone number highlighted in navy bold in the subtitle
- 6 Pinput boxes: white bg, grey border, navy focused border + glow, navy filled bg + white digit
- Feedback banner: same component as phone entry — slide in, auto dismiss
- Resend: countdown timer with navy bold seconds, gold Resend when timer hits 0
- Keyboard aware: same floating button pattern

### Key details
- Used _canResend bool to control resend display — more reliable than countdown > 0
- Timer fix: cancel + reset both _resendCooldown and _canResend in _startCooldown
- pinput submittedPinTheme: navy bg, white text — filled boxes look confirmed

## [2026-03-12] - Onboarding Modularization
- **Issue:** Build failure due to syntax error in monolith `onboarding_screen.dart`.
- **Action:** Split `onboarding_screen.dart` into 4 modular widgets and 1 coordinator screen.
- **Logic:** Moved database insertion logic (`createUser`, `createProfile`) from UI layer to `AuthNotifier`.
- **Result:** Resolved syntax errors and enforced logic/UI separation.

## [2026-03-12] — Environment Reset for Onboarding Test
**Change type:** chore
**Files affected:** Database (Supabase)
**Why:** To verify the fix for the modularized onboarding flow from a zero-data state.
**What changed:** Deleted test user '+233200000001' from auth.users and public.users.
**Risk:** None. CASCADE delete ensured all dependent records (profiles, jobs) were removed.

## [2026-03-12] — Environment Reset for Onboarding Test
**Change type:** chore
**Files affected:** Database (Supabase)
**Why:** To verify the modular onboarding flow and router redirection from a zero-data state.
**What changed:** Deleted test user '+233200000001' from auth.users. 
**Modularity note:** N/A (Data cleanup)
**Tests:** N/A
**Risk:** None. CASCADE delete ensured all dependent records were removed cleanly.

---
## SESSION 10 — Linting and ID Mismatch Resolution

### What was built
- Resolved 38 linting issues across the authentication flow.
- Added `const` optimizations to `app_text_styles.dart` and auth screens.
- Replaced deprecated `withOpacity` with `withValues` for Flutter 3.41.4 compliance.

### What broke and how it was fixed
- **BREAK**: Onboarding profile creation failed due to ID mismatch.
- **Cause**: Repository was using Supabase Auth ID instead of the internal User ID for the `profiles` table.
- **Fix**: Updated `ProfileRepositoryImpl` to use `profile.userId` from the entity.
- **Diagnostic**: Added structured logging `[KS:PROFILE]` to remote datasource and repository.

### Flutter analyze status
No issues found ✅

---
## SESSION 12 — Compilation Recovery & Dependency Alignment

### What was built
- Fixed 17+ compilation errors related to provider scope and type mismatches.
- Properly implemented `AsyncValue` unwrapping in the `AppRouter`.
- Aligned `AuthNotifier` with the `Params` pattern for use cases.

### What was fixed
- **Ambiguous Imports**: Resolved `AuthException` collisions between Supabase and local error classes.
- **Provider Scope**: Defined missing repository and use case providers within the Auth feature.
- **Interface Stability**: Corrected `verifyOtp` return types and `createUser` parameter naming.

### Status
- **Flutter Analyze**: No issues found ✅
- **Next Goal**: Functional end-to-end test of the onboarding flow.

---
## SESSION 13 — URI Host Resolution

### What was fixed
- **ISSUE**: `AuthException: Invalid argument(s): No host specified in URI` during OTP request.
- **CAUSE**: `SupabaseConstants` used `String.fromEnvironment` but values were missing when launching via standard `flutter run`.
- **FIX**: Hardcoded Supabase URL and Anon Key directly into `lib/core/constants/supabase_constants.dart` based on values in `run.sh`.

---
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

---

## SESSION 5 — 2026-03-10

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

## SESSION 6 — 2026-03-10

### What was built
- Diagnosed and fixed 3 auth flow bugs that were breaking the core user journey

### What broke and how it was fixed

BREAK 1: OTP verify had a double-navigation race condition
  File: lib/features/auth/presentation/screens/otp_verify_screen.dart
  Cause: _onVerify() manually called context.go() AND invalidated authStateProvider,
         which triggered the router's _RouterNotifier to also navigate simultaneously.
         Two navigations firing at once caused unpredictable behaviour.
  Fix: Removed all manual context.go() calls from _onVerify(). Now only calls
       ref.invalidate(authStateProvider) and lets the router redirect handle navigation.
  Also removed unused route_names.dart import. Kept go_router import for context.pop().

BREAK 2: Onboarding completed but router immediately bounced user back to onboarding
  File: lib/features/auth/presentation/screens/onboarding_screen.dart
  Cause: After saving profile, screen called context.go(RouteNames.jobs) but never
         invalidated authStateProvider. Router still had hasProfile=false in its state,
         so the redirect rule (_isAuthenticated && !_hasProfile → onboarding) fired
         and sent the user straight back.
  Fix: Replaced context.go(RouteNames.jobs) with ref.invalidate(authStateProvider).
       Router now re-reads auth state, sees hasProfile=true, and navigates to /jobs.
  Also removed unused go_router and route_names imports, added auth_provider import.

BREAK 3: Sign out could crash with null error before redirect fired
  File: lib/features/technician_profile/data/repositories/profile_repository_impl.dart
  Cause: String get _userId => _supabase.auth.currentUser!.id used bang operator.
         After signOut(), currentUser becomes null. Any profileProvider rebuild
         during the sign-out window would throw a null crash before the router
         could redirect away from the profile screen.
  Fix: Changed to _supabase.auth.currentUser?.id ?? '' — safe null handling.

### Flutter analyze status
No issues found ✅

### What comes next
- Test the full auth flow on physical device:
  Phone → OTP → Onboarding → Jobs → Profile → Sign out → Phone entry
- If all passing: Phase 9 remaining work (PublicProfileScreen, photo upload)
- Then Phase 10: Polish and production readiness

---

## SESSION 6 CONTINUED — 2026-03-10

### What was built
- Added structured debug logging to auth flow
- All KS:AUTH and KS:AUTH_STATE log lines now print to terminal during testing
- Logging covers: requestOtp, verifyOtp, getCurrentUser, createUser, signOut, onAuthStateChange, profile check

### What broke and how it was fixed
BREAK: debugPrint not available in AuthRemoteDatasource
  Cause: missing flutter/foundation.dart import
  Fix: full rewrite of auth_remote_datasource.dart with import added

BREAK: string concatenation warnings in auth_provider.dart
  Cause: used + operator instead of string interpolation in debugPrint calls
  Fix: full rewrite of auth_provider.dart using interpolation throughout

### Key learning
- Surgical patching with bash heredoc is unreliable — bash interprets $, !, and em-dashes
- Full file rewrites using python3 << PYEOF are the correct approach for every file change
- Never use inline python3 -c with multi-line strings containing special characters

### Flutter analyze status
No issues found

### What comes next
- Run app with two terminals
- Terminal 1: bash run.sh
- Terminal 2: flutter logs | grep KS:
- Test full auth flow and paste Terminal 2 output to diagnose any remaining issues

---

## SESSION 6 CONTINUED — 2026-03-10

### What was built
- Added structured debug logging to auth flow
- All KS:AUTH and KS:AUTH_STATE log lines now print to terminal during testing
- Logging covers: requestOtp, verifyOtp, getCurrentUser, createUser, signOut, onAuthStateChange, profile check

### What broke and how it was fixed
BREAK: debugPrint not available in AuthRemoteDatasource
  Cause: missing flutter/foundation.dart import
  Fix: full rewrite of auth_remote_datasource.dart with import added

BREAK: string concatenation warnings in auth_provider.dart
  Cause: used + operator instead of string interpolation in debugPrint calls
  Fix: full rewrite of auth_provider.dart using interpolation throughout

### Key learning
- Surgical patching with bash heredoc is unreliable — bash interprets $, !, and em-dashes
- Full file rewrites using python3 << PYEOF are the correct approach for every file change
- Never use inline python3 -c with multi-line strings containing special characters

### Flutter analyze status
No issues found

### What comes next
- Run app with two terminals
- Terminal 1: bash run.sh
- Terminal 2: flutter logs | grep KS:
- Test full auth flow and paste Terminal 2 output to diagnose any remaining issues

---

## SESSION 6 FINAL — 2026-03-10

### What was built
- Full auth flow working end to end on physical device
- Phone entry → OTP → Jobs dashboard
- Jobs dashboard → Profile → Sign out → Phone entry
- Clean log output — no loops, no crashes

### What broke and how it was fixed

BREAK 1: OTP verify had double-navigation race condition
  File: otp_verify_screen.dart
  Cause: screen manually called context.go() AND invalidated authStateProvider
         simultaneously — two navigations racing each other
  Fix: removed all manual context.go() calls — router redirect handles navigation

BREAK 2: Onboarding bounced user back to onboarding after saving profile
  File: onboarding_screen.dart
  Cause: context.go(RouteNames.jobs) called but authStateProvider never invalidated
         so router still saw hasProfile=false and redirected back
  Fix: replaced context.go() with ref.invalidate(authStateProvider)

BREAK 3: Profile screen crashed on sign out
  File: profile_repository_impl.dart
  Cause: _userId getter used bang operator _supabase.auth.currentUser!.id
         after signOut() currentUser becomes null — null crash before router redirect
  Fix: changed to _supabase.auth.currentUser?.id ?? '' safe null handling

BREAK 4: Infinite rebuild loop on initialSession event
  File: auth_provider.dart
  Cause: onAuthStateChange listener called ref.invalidateSelf() on every event
         including initialSession. Supabase replays current auth state to every
         new listener. So every invalidateSelf() created a new notifier, new listener,
         new initialSession event, new invalidateSelf() — infinite loop
  Fix: filtered to only react to initialSession events — but signedIn still looped

BREAK 5: Infinite rebuild loop on signedIn event
  File: auth_provider.dart
  Cause: same root cause as BREAK 4 — signedIn also replayed to new listeners
         Every invalidateSelf() → new build() → new listener → signedIn replayed
  Fix attempted: filter signedIn too — but pattern is fundamentally broken

BREAK 6: Root cause identified and fixed — onAuthStateChange listener removed entirely
  File: auth_provider.dart
  Cause: The fundamental problem is that Supabase onAuthStateChange replays
         current auth state to every new subscriber. Since Riverpod creates a new
         notifier (and new listener) on every invalidateSelf(), any event that
         triggers invalidateSelf() inside the listener causes an infinite loop.
         This is not fixable by filtering events — the architecture is wrong.
  Fix: Removed onAuthStateChange listener completely from AuthNotifier.build()
       Added explicit refresh() method — called once from otp_verify_screen after
       successful OTP verify
       signOut() already calls invalidateSelf() directly — no listener needed
       Result: authStateProvider only rebuilds when explicitly told to

### What was learned
1. Supabase onAuthStateChange replays current state to every new subscriber
   Never call invalidateSelf() inside an onAuthStateChange listener — infinite loop
   Always trigger auth state rebuilds explicitly from the call site instead

2. Surgical patching with bash heredoc is unreliable
   Bash interprets $, !, em-dashes inside heredocs
   Always use python3 << PYEOF for file writes
   Always do full file rewrites — never surgical string replacement

3. ref.watch() inside AsyncNotifier.build() causes rebuild loops
   Use ref.read() for providers that do not change (like supabaseClientProvider)

4. Router redirect depends on authStateProvider — not profileProvider
   Invalidating profileProvider alone does not trigger router redirect
   Must invalidate authStateProvider to make router re-evaluate redirect rules

5. Two sources of truth = bugs
   Never force state manually (e.g. forceProfileComplete())
   Always derive state from database — invalidate and let provider refetch

### Flutter analyze status
No issues found

### Device test
App boots → straight to jobs (session persisted) ✅
Sign out → phone entry screen ✅
Phone entry → OTP → jobs dashboard ✅
Full auth flow clean with no loops ✅

### What comes next
- Phase 9 remaining: PublicProfileScreen, photo upload flow
- Phase 10: Polish and production readiness
- Checkpoint 4: Full smoke test

---

## SESSION 7 — 2026-03-10

### What was built
- Phase 9 complete: Technician Profile feature
- PublicProfileScreen — displays profile publicly via /p/:slug route, no auth required
- Photo upload flow wired into EditProfileScreen — image picker, upload to Supabase storage, pending URL saved on profile update
- publicProfileProvider added to profile_provider.dart using FutureProvider.family
- Router updated — replaced stub with real PublicProfileScreen
- Debug logging added to ProfileNotifier (load, update, uploadPhoto)

### What broke and how it was fixed
No breaks this session — clean build first attempt

### Flutter analyze status
No issues found

### Device test
- To be tested: edit profile photo upload
- To be tested: public profile via share link
- To be tested: WhatsApp CTA on public profile

### What comes next
- Phase 10: Polish and production readiness (Steps 63-70)
  - Step 63: Offline banner animations
  - Step 64: Skeleton loaders on all list screens
  - Step 65: Pull-to-refresh on all list screens
  - Step 66: Unsaved changes dialogs on all edit screens
  - Step 67: Analytics events
  - Step 68: Error boundary in app.dart
  - Step 69: app_events Supabase table
  - Step 70: Pre-release checklist
- Checkpoint 4: Full smoke test on physical device

---

## SESSION 7 CONTINUED — Phase 10 complete

### What was built
- Step 66: Unsaved changes dialogs — PopScope added to all 4 edit screens (log_job, add_note, add_customer, edit_profile)
- Step 67: Analytics — KsAnalytics helper created, fire-and-forget events wired into job_logged, note_saved, customer_added, profile_shared
- Step 68: Error boundary — _ErrorBoundary widget wraps entire app, catches Flutter errors, shows restart screen
- Step 69: app_events Supabase table created with RLS — authenticated users can insert and select own events
- Steps 63-65 were already complete from previous phases (offline banner, skeleton loaders, pull-to-refresh)

### Lessons
- PopScope.onPopInvokedWithResult — capture Navigator.of(context) BEFORE the await to avoid use_build_context_synchronously warning
- Analytics must never throw — always wrap in try/catch, fire and forget
- AppColors.error700 does not exist — use error600

### Flutter analyze status
No issues found

### Device test
- To be tested: unsaved changes dialog on back press
- To be tested: analytics events appearing in app_events table

### What comes next
- Checkpoint 4: Full smoke test on physical device — all 5 features + offline + sync
- Step 70: Pre-release checklist
- UI design and mockups phase (separate track)
- Domain registration: keystone.app

---

## SESSION 7 — Bug fix: photo upload

### What broke
Photo upload returning 403 Unauthorized from Supabase storage

### Root cause
storage_profile_photos_insert RLS policy was assigned to {public} role instead of {authenticated}
Authenticated users were being blocked by their own upload policy

### Fix
1. Dropped and recreated storage_profile_photos_insert with TO authenticated
2. Did same for storage_note_photos_insert
3. Added cache-busting timestamp to uploaded photo URL (?t=milliseconds)
   — Without this, NetworkImage shows cached old photo even after successful upload

### Lesson
Always check the roles column on storage RLS policies — {public} and {authenticated} are different
Supabase storage upsert needs both INSERT and UPDATE policies for overwriting existing files

### Device test
Photo upload — SUCCESS
New photo displays immediately after save — SUCCESS

---

## SESSION 7 — Checkpoint 4 complete

### Smoke test results
- Auth flow: PASS
- Log job online: PASS
- Log job offline + sync: PASS
- Add customer: PASS
- Add note: PASS
- Sign out / sign back in: PASS
- Photo upload: PASS
- Unsaved changes dialog: PASS

### Bugs fixed during checkpoint
1. Photo upload 403 — storage RLS policy was {public} not {authenticated}
2. Photo not updating — NetworkImage caches by URL — fixed with cache-busting timestamp
3. Unsaved changes dialog not showing — KsAppBar called Navigator.pop() directly bypassing PopScope
   Fix: changed to Navigator.maybePop() which respects PopScope.canPop
4. PopScope not intercepting Android back gesture — missing android:enableOnBackInvokedCallback="true" in manifest

### What comes next
- Step 70: Pre-release checklist
- Domain registration: keystone.app
- UI design and mockups phase
- Play Store submission prep

---

## SESSION 9 — App Icon & Splash Screen

### Goal
Design and implement the Keystone app icon and splash screen.

### Icon Design Process
- Concept: arch with keystone block at crown, keyhole inside keystone block
- Colors: navy blue (#1A237E) arch, gold (#F9A825) keystone, navy keyhole
- Used AI image generator (Gemini) iteratively to refine the design
- Key iterations:
  1. First attempt — key symbol too detailed, arch legs cut off
  2. Second attempt — keyhole cleaner, arch had proper base — best open arch version
  3. Tried solid arch — looked like a mailbox, lost arch character
  4. Switched to white arch on navy background — strong but generator kept adding rounded square container
  5. Went back to isolated logo on white background approach
  6. Final logo saved as logos.png (1248x1248 RGBA) from Adobe Express

### Splash Screen — Long Journey
Iterations and lessons learned:

1. **Manual PNG approach** — placed logo PNG directly in drawable folder
   - Problem: Android bitmap tag scales image down no matter how large the PNG
   - Result: always small and sometimes blurry

2. **flutter_native_splash package** — correct tool for the job
   - Generates splash files for all Android densities automatically
   - Controls size through canvas proportion — logo size relative to canvas
   - CRITICAL LESSON: this package must be added, used to generate, then REMOVED
   - Reason: flutter_native_splash has its own build.gradle requiring AGP 8.7.0
   - AGP 8.7.0 cannot be downloaded on this network (dl.google.com blocked)
   - Project uses AGP 8.11.1 which is cached — conflict cannot be resolved
   - Workflow every time splash needs updating:
       1. flutter pub add dev:flutter_native_splash
       2. dart run flutter_native_splash:create --path=flutter_native_splash.yaml
       3. flutter pub remove flutter_native_splash
       4. run.sh

3. **SVG attempt** — tried using logo.svg thinking it was true vector
   - Problem: the SVG was just a wrapper around an embedded PNG (created by Inkscape)
   - rsvg-convert rendered it tiny because the embedded PNG was small
   - Lesson: always verify SVG is true vector paths, not embedded raster

4. **Final solution** — use logos.png (1248x1248) as source, render at exact dimensions
   - Canvas: 1080x1920 (standard phone screen)
   - Logo: 900x1300 (slightly taller than wide to show full arch with legs)
   - Logo centered on canvas
   - Result: clear, sharp, well proportioned splash screen

### Final Splash Dimensions
- Canvas: 1080 x 1920
- Logo: 900 x 1300
- Source: ~/Downloads/logos.png

### App Icon
- White background square canvas
- Logo centered with padding
- Generated all Android mipmap sizes from master 1024x1024

### Key Rules Learned
- flutter_native_splash: add → generate → remove (every time)
- SVG from Inkscape may contain embedded PNG — verify before using
- Control splash logo size through canvas proportion, not package parameters
- Never scale PNG above its source resolution — causes blur
- logos.png (1248x1248) is the master source for all icon/splash work

---

## SESSION 9 CONTINUED — KsLogo SVG Implementation

### Goal
Create a pixel-perfect programmatically controllable Flutter logo widget.

### The Long Journey

**Attempt 1 — CustomPainter from scratch**
- Drew arch, keystone, keyhole manually using cubic bezier curves
- Result: looked like a horseshoe — single continuous arch, not two separate arms
- Lesson: cannot guess path coordinates for a complex logo — need exact data

**Attempt 2 — Inkscape trace by color**
- Traced logos.png in Inkscape using color mode
- Problem: both arms and keyhole are same navy color — Inkscape merged them into one object
- Used Path → Break Apart to separate sub-paths
- Got 4 separate parts: left_arm, right_arm, keystone_block, keyhole
- Exported each as individual SVG

**Attempt 3 — flutter_svg with Stack positioning**
- Tried placing each SVG part in a Flutter Stack at calculated positions
- Problem: each exported SVG has its own coordinate system starting at 0,0
- Parts lost their original positions relative to each other
- Result: scattered, wrong positions

**Attempt 4 — Combined SVG with translate**
- Tried combining parts using SVG transform="translate(x,y)"
- Problem: mm vs px unit confusion caused parts to not render
- Multiple iterations, still not working

**Attempt 5 — svgpathtools analysis**
- Installed svgpathtools to analyze path coordinates
- Confirmed all parts start at 0,0 — no original position data preserved
- Tried calculating positions manually — keyhole still wrong

**The Breakthrough — Full combined SVG from Inkscape**
- Instead of combining parts manually, went back to Inkscape
- Selected all parts together and exported as one complete SVG
- This preserved the original coordinate relationships between all parts
- Result: perfect logo with all parts in exact correct positions

**Final Solution**
- Complete SVG with 4 named paths: keystone_block, keyhole, right_arm, left_arm
- Cleaned up SVG — removed style= attributes, kept only fill= attributes
- Each path has its own id for programmatic control
- Saved as: assets/logo/ks_logo_combined.svg
- KsLogo widget uses flutter_svg SvgPicture.asset to render it

### Key Lessons Learned
1. Never try to manually reassemble SVG parts that were exported individually
2. The correct workflow is: arrange all parts in Inkscape → export the whole thing as one SVG
3. Individual part exports lose their position context — useless for reassembly
4. flutter_svg renders SVG perfectly at any size — no blur, no scaling issues
5. Clean SVG = fill attributes only, no style= tags, named ids on each path

### What We Now Have
- ks_logo_combined.svg with 4 independently addressable paths
- Fully programmatic — colors changeable at runtime
- Scalable to any size with zero blur
- Ready for animations, theming, dark mode

### File Locations
- SVG: assets/logo/ks_logo_combined.svg
- Widget: lib/core/widgets/ks_logo.dart
- Parts data: assets/logo/parts_data.json (reference)
- Individual parts: assets/logo/left_arm.svg, right_arm.svg, keystone_block.svg, keyhole.svg

---

## SESSION 10 — Landing Screen & Font System

### Font System
- Added Barlow Semi Condensed full family (18 variants) to assets/fonts/
- Registered all weights (100-900) and italic variants in pubspec.yaml
- Replaced all GoogleFonts.inter() calls in app_text_styles.dart with
  TextStyle(fontFamily: 'BarlowSemiCondensed')
- Removed google_fonts import from app_text_styles.dart
- Rule: all text in app uses BarlowSemiCondensed, weight 600+ preferred

### Landing Screen — New Screen Created
File: lib/features/auth/presentation/screens/landing_screen.dart

Design concept: split screen
- Top 62%: off-white #FAFAF8 background, logo centered, text block
- Bottom 38%: deep navy #1A237E background, gold CTA button, sign in link

Layout (top to bottom):
- KsLogo 170px centered with fade+slide entrance animation
- Gold spaced label: LOCKSMITH MANAGEMENT (11px, weight 600, tracking 3.5)
- Keystone (54px, weight 800, navy)
- Subtitle: Built for Ghana's professional locksmiths (17px, weight 600, grey)
- Gold button: Get Started (navy bg bottom section, gold button)
- Sign in line: RichText — white70 + gold Sign in (weight 700)

Animations: staggered entrance via AnimationController 1400ms
- Logo: fade + slide up (0-50%)
- Text: fade in (30-65%)
- Button: fade in (60-100%)

Typography decisions:
- All weights 600+ only — no thin or regular weight text
- No underlines on links — use color contrast instead
- Two-tone RichText for "Already have an account? Sign in"

### Router Updates
- Added RouteNames.landing = '/'
- Initial location changed from phoneEntry to landing
- Redirect logic: unauthenticated users go to landing not phoneEntry
- Authenticated users bypass landing entirely → jobs dashboard

### Key Design Lessons
1. Split screen (light top / dark bottom) creates strong visual hierarchy
2. Gold accent on navy is the brand signature — use it for all CTAs
3. Never underline links in mobile — use color contrast
4. BarlowSemiCondensed at 800 weight is the hero font for this app
5. RichText for mixed-style inline text (no wrapping widgets needed)

---

## SESSION 10 CONTINUED — Phone Entry Screen Redesign

### Design
- Removed KsLogo and Keystone title — user already saw them on landing screen
- Icon badge: navy rounded square, gold mobile icon (28px) — establishes screen identity
- Split layout: off-white top / navy bottom — consistent with landing screen language
- Heading: 38px w800 navy, left-aligned — task-focused not brand moment
- Subtitle: 16px w600 grey
- Unified phone input: one seamless box, no divider between flag and number field
- Ghana flag SVG + +233 prefix left side, number input flows naturally right
- Gold check icon when number is valid, grey X when invalid
- Animated feedback banner: slides in from top, red for error, green for success, auto-dismisses after 4s
- Keyboard aware: navy bottom hides when keyboard opens, floating navy Continue button appears above keyboard instead

### Files changed
- lib/features/auth/presentation/screens/phone_entry_screen.dart — full rewrite
- assets/flags/gh.svg — Ghana flag downloaded from flagcdn.com
- pubspec.yaml — assets/flags/ registered

### Packages used
- flutter_svg — renders Ghana flag
- line_awesome_flutter — back arrow, mobile icon, check, X, error icons

### Key lessons
- Never use Row with BoxDecoration border to split a text field — it creates a visible divider
- For prefix + input in one box: use Padding widget for prefix, TextField with InputBorder.none for input
- hot reload does not re-run initState — LateInitializationError means you need full restart
- keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0 is reliable for keyboard detection

---

## SESSION 10 CONTINUED — OTP Verify Screen Redesign

### Design
- Same pattern as phone entry: off-white top / navy bottom
- Icon badge: navy square, gold shield icon (28px)
- Heading: "Verify your number" 38px w800
- Phone number highlighted in navy bold in the subtitle
- 6 Pinput boxes: white bg, grey border, navy focused border + glow, navy filled bg + white digit
- Feedback banner: same component as phone entry — slide in, auto dismiss
- Resend: countdown timer with navy bold seconds, gold Resend when timer hits 0
- Keyboard aware: same floating button pattern

### Key details
- Used _canResend bool to control resend display — more reliable than countdown > 0
- Timer fix: cancel + reset both _resendCooldown and _canResend in _startCooldown
- pinput submittedPinTheme: navy bg, white text — filled boxes look confirmed

## [2026-03-12] - Onboarding Modularization
- **Issue:** Build failure due to syntax error in monolith `onboarding_screen.dart`.
- **Action:** Split `onboarding_screen.dart` into 4 modular widgets and 1 coordinator screen.
- **Logic:** Moved database insertion logic (`createUser`, `createProfile`) from UI layer to `AuthNotifier`.
- **Result:** Resolved syntax errors and enforced logic/UI separation.

## [2026-03-12] — Environment Reset for Onboarding Test
**Change type:** chore
**Files affected:** Database (Supabase)
**Why:** To verify the fix for the modularized onboarding flow from a zero-data state.
**What changed:** Deleted test user '+233200000001' from auth.users and public.users.
**Risk:** None. CASCADE delete ensured all dependent records (profiles, jobs) were removed.

## [2026-03-12] — Environment Reset for Onboarding Test
**Change type:** chore
**Files affected:** Database (Supabase)
**Why:** To verify the modular onboarding flow and router redirection from a zero-data state.
**What changed:** Deleted test user '+233200000001' from auth.users. 
**Modularity note:** N/A (Data cleanup)
**Tests:** N/A
**Risk:** None. CASCADE delete ensured all dependent records were removed cleanly.

---
## SESSION 10 — Linting and ID Mismatch Resolution

### What was built
- Resolved 38 linting issues across the authentication flow.
- Added `const` optimizations to `app_text_styles.dart` and auth screens.
- Replaced deprecated `withOpacity` with `withValues` for Flutter 3.41.4 compliance.

### What broke and how it was fixed
- **BREAK**: Onboarding profile creation failed due to ID mismatch.
- **Cause**: Repository was using Supabase Auth ID instead of the internal User ID for the `profiles` table.
- **Fix**: Updated `ProfileRepositoryImpl` to use `profile.userId` from the entity.
- **Diagnostic**: Added structured logging `[KS:PROFILE]` to remote datasource and repository.

### Flutter analyze status
No issues found ✅

---
## 2026-03-12 — Supabase Identity & RLS Resolution

**Change type:** architectural fix
**Files affected:** auth_notifier.dart, verify_otp_usecase.dart, profile_repository_impl.dart, app_router.dart
**Why:** Critical failure during onboarding where the profiles table rejected Auth UIDs due to a 'cross-wired' RLS policy and normalization mismatch.
**What changed:** - **Normalization:** Updated  to normalize phone numbers to E.164, matching the request stage.
- **Identity Duality:** Standardized  to use the Supabase **Auth UID** for profile creation while preserving the **Internal UUID** for business logic.
- **Idempotency:** Added a  check in  to handle retries safely.
- **RLS Fix:** (Database side) Rewrote profile policies to check  directly against .
- **Routing:** Registered missing feature routes in  to resolve '/jobs/new' navigation crashes.
**Risk:** High. All developers must now consult the  in .

---
## 2026-03-12 — Job Logging ID Alignment

**Change type:** fix
**Files affected:** job_providers.dart, auth_provider.dart
**Why:** Job logging was failing because the app passed the Auth UID to a column expecting the internal .
**What changed:** - **Provider:** Introduced  to fetch and cache the full .
- **Logic Fix:** Updated  to read the internal UUID from the provider before saving a job.
**Tests:** End-to-end verified from Landing -> Dashboard -> Job Log.


---
## 2026-03-12 — Fixed Onboarding Profile ID Mismatch

**Change type:** fix
**Files affected:** profile_remote_datasource.dart, profile_repository_impl.dart
**Why:** Profile creation was failing due to using Supabase Auth ID instead of internal User ID.
**What changed:** - Added debug logging to Profile layers.
- Fixed repository to use `profile.userId` (internal UUID) during creation.
**Tests:** Pending device verification.

---
## 2026-03-12 — Linting Cleanup

**Change type:** chore
**Files affected:** app_text_styles.dart, landing_screen.dart, otp_verify_screen.dart, phone_entry_screen.dart, auth_header.dart, name_step_view.dart, onboarding_bottom_bar.dart, services_step_view.dart
**Why:** Resolved 38 issues found by flutter analyze to maintain code quality.
**What changed:** - Added missing const keywords to constructors and literals.
- Removed unnecessary services.dart import in phone_entry_screen.dart.
- Replaced deprecated withOpacity with withValues for color alpha management.
**Modularity note:** Code remains strictly modular and follows Flutter 3.41.4 standards.
**Tests:** flutter analyze
**Risk:** None. Cosmetic and architectural cleanup.

---
## 2026-03-12 — Final Linting Resolution

**Change type:** chore
**Files affected:** landing_screen.dart, otp_verify_screen.dart, phone_entry_screen.dart
**Why:** Resolved the final 7 "prefer_const_constructors" and "prefer_const_literals" issues.
**What changed:** Applied const to Column children, TextStyle objects, and Icon widgets in the auth flow screens.
**Modularity note:** Code is now 100% compliant with the project's analysis rules.
**Tests:** flutter analyze
**Risk:** None.

---
## 2026-03-12 — Final Linting Resolution

**Change type:** chore
**Files affected:** landing_screen.dart, otp_verify_screen.dart, phone_entry_screen.dart
**Why:** Resolved the final 7 "prefer_const_constructors" and "prefer_const_literals" issues.
**What changed:** Applied const to Column children, TextStyle objects, and Icon widgets in the auth flow screens.
**Modularity note:** Code is now 100% compliant with the project's analysis rules.
**Tests:** flutter analyze
**Risk:** None.

---
## [2026-03-12] — Logo Color Synchronization

**Change type:** fix
**Files affected:** lib/core/widgets/ks_logo.dart, lib/core/widgets/ks_logo_animated.dart, assets/logo/*.svg
**Why:** The logo was using inconsistent navy shades and incorrect gold values.
**What changed:** Updated native SVG fill colors to brand specs and standardized ColorFilters in widgets to use primary900 and accent500.
**Modularity note:** Confirmed logo widgets remain pure UI coordinators.
**Tests:** Passed analysis.
**Risk:** None.

---
## SESSION 12 — Compilation Recovery & Dependency Alignment

### What was built
- Fixed 17+ compilation errors related to provider scope and type mismatches.
- Properly implemented `AsyncValue` unwrapping in the `AppRouter`.
- Aligned `AuthNotifier` with the `Params` pattern for use cases.

### What was fixed
- **Ambiguous Imports**: Resolved `AuthException` collisions between Supabase and local error classes.
- **Provider Scope**: Defined missing repository and use case providers within the Auth feature.
- **Interface Stability**: Corrected `verifyOtp` return types and `createUser` parameter naming.

### Status
- **Flutter Analyze**: No issues found ✅
- **Next Goal**: Functional end-to-end test of the onboarding flow.

---
## SESSION 13 — URI Host Resolution

### What was fixed
- **ISSUE**: `AuthException: Invalid argument(s): No host specified in URI` during OTP request.
- **CAUSE**: `SupabaseConstants` used `String.fromEnvironment` but values were missing when launching via standard `flutter run`.
- **FIX**: Hardcoded Supabase URL and Anon Key directly into `lib/core/constants/supabase_constants.dart` based on values in `run.sh`.

---
## 2026-03-13 — UI/UX Industrial Overhaul & Simplification

**Change type:** UI/UX redesign
**Files affected:** ks_app_bar.dart, ks_bottom_nav.dart, job_list_screen.dart, job_card.dart, log_job_screen.dart, customer_list_screen.dart, customer_card.dart
**Why:** The application required a consistent, high-contrast industrial aesthetic and simpler language to ensure it is easy for technicians to use in the field without confusion.
**What changed:** - **Theming:** Transitioned all screens from a light theme to a "Primary900" dark industrial theme.
- **Components:** Updated the Dashboard Shell with a custom bottom navigation featuring an "Accent500" (Gold) active-tab circuit line.
- **Visuals:** Replaced standard icons with LineAwesomeIcons for a sharper, professional look.
- **Bug Fix:** Resolved the "white-out" visibility issue in dark text fields by applying transparent fills to the input decoration.
- **UX Copy:** Simplified all technical jargon into plain English (e.g., "Log Deployment" changed to "Add New Job").
**Tests:** Hot Reload verified on all updated screens.
**Risk:** Low. Strictly UI and text label updates.


---
## 2026-03-13 — UI/UX Industrial Overhaul & Simplification

**Change type:** UI/UX redesign
**Files affected:** ks_app_bar.dart, ks_bottom_nav.dart, job_list_screen.dart, job_card.dart, log_job_screen.dart, customer_list_screen.dart, customer_card.dart
**Why:** The application required a consistent, high-contrast industrial aesthetic and simpler language to ensure it is easy for technicians to use in the field without confusion.
**What changed:** - **Theming:** Transitioned all screens from a light theme to a "Primary900" dark industrial theme.
- **Components:** Updated the Dashboard Shell with a custom bottom navigation featuring an "Accent500" (Gold) active-tab circuit line.
- **Visuals:** Replaced standard icons with LineAwesomeIcons for a sharper, professional look.
- **Bug Fix:** Resolved the "white-out" visibility issue in dark text fields by applying transparent fills to the input decoration.
- **UX Copy:** Simplified all technical jargon into plain English (e.g., "Log Deployment" changed to "Add New Job").
**Tests:** Hot Reload verified on all updated screens.
**Risk:** Low. Strictly UI and text label updates.


---
## 2026-03-13 — UI/UX Industrial Overhaul & Simplification

**Change type:** UI/UX redesign
**Files affected:** ks_app_bar.dart, ks_bottom_nav.dart, job_list_screen.dart, job_card.dart, log_job_screen.dart, customer_list_screen.dart, customer_card.dart
**Why:** The application required a consistent, high-contrast industrial aesthetic and simpler language to ensure it is easy for technicians to use in the field without confusion.
**What changed:** - **Theming:** Transitioned all screens from a light theme to a "Primary900" dark industrial theme.
- **Components:** Updated the Dashboard Shell with a custom bottom navigation featuring an "Accent500" (Gold) active-tab circuit line.
- **Visuals:** Replaced standard icons with LineAwesomeIcons for a sharper, professional look.
- **Bug Fix:** Resolved the "white-out" visibility issue in dark text fields by applying transparent fills to the input decoration.
- **UX Copy:** Simplified all technical jargon into plain English (e.g., "Log Deployment" changed to "Add New Job").
**Tests:** Hot Reload verified on all updated screens.
**Risk:** Low. Strictly UI and text label updates.


---
## 2026-03-13 — Add Note & Tag Input Industrialization

**Change type:** UI/UX Redesign
**Files affected:** add_note_screen.dart, tag_input_field.dart
**Why:** To align the technical knowledge base with the dark industrial theme and fix the "white-out" visibility bug in custom input components.
**What changed:** - **Theming:** Applied Primary900/800 theme to the Add Note form.
- **Custom Widget:** Redesigned the TagInputField to be fully transparent with Accent500 (Gold) tactical chips.
- **Bug Fix:** Implemented fillColor: Colors.transparent to resolve background clashing in custom text fields.
**Tests:** Hot Reload verified.

---
## 2026-03-13 — Job Detail & Follow-up Implementation

**Change type:** Feature Addition
**Files affected:** job_detail_screen.dart, follow_up_button.dart, follow_up_message_preview.dart, job_providers.dart
**Why:** To complete the core value loop (Log Job -> Send Follow-up) and provide a professional technical report for technicians.
**What changed:** - **New Screen:** Created JobDetailScreen with hardware-style modules.
- **Components:** Built Message Preview and a high-contrast Action Bar for WhatsApp integration.
- **Provider:** Added jobDetailProvider to fetch single job records by ID.
**Tests:** UI verified. Navigation to WhatsApp confirmed via launcher utility.

---
## 2026-03-13 — Customer Dossier & Profile Industrialization

**Change type:** UI/UX Redesign & Feature Alignment
**Files affected:** customer_detail_screen.dart, profile_screen.dart, app_router.dart, customer_providers.dart
**Why:** To transition the remaining core screens into the "Primary900" dark industrial theme and ensure seamless navigation between the Customer Dossier and Job Logging.
**What changed:** - **Customer Dossier:** Replaced standard Material detail with a "Technical Dossier" view featuring a live service ledger and tactical stats.
- **Profile Screen:** Simplified to a clean dark theme using correct ProfileEntity fields (whatsappNumber) and fixing the AuthProvider import level.
- **Navigation:** Updated GoRouter to accept customerId as an extra parameter for pre-filling jobs from the dossier.
- **Dependency Repair:** Fixed relative import paths and matched Enum string formatting (ServiceType) to resolve runtime NoSuchMethodErrors.
**Tests:** Hot Reload and Hot Restart verified.
