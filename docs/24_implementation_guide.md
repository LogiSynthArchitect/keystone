# DOCUMENT 24 — IMPLEMENTATION GUIDE
### Project: Keystone
**Required Inputs:** All 23 preceding documents
**Purpose:** Developer handoff — day one to launch in exact sequence
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 24.1 Before You Write a Single Line of Code

Read these documents in order. Do not skip.

01 → Problem Brief        — know who you are building for and why
03 → Core Hypothesis      — know what V1 must prove
04 → Core Scope           — know exactly what ships and what does not
07 → Domain Model         — know every entity and relationship
12 → Database Schema      — know the data foundation
13 → Flutter Architecture — know the folder rules before creating any file
14 → Design System        — know the colors and tokens before building any widget

Everything else is reference — consult as needed while building.

---

## 24.2 Environment Setup

Required tools:
flutter --version  # 3.22.0 or later, stable channel
java -version      # JDK 17.x (required for Android builds)
Android SDK: min API 21 / target API 34
supabase --version # npm install -g supabase

Create project:
flutter create keystone --org com.keystone --project-name keystone --platforms android
cd keystone

---

## 24.3 Folder Structure Script

mkdir -p lib/core/constants lib/core/errors lib/core/network
mkdir -p lib/core/storage/isar_schemas lib/core/providers lib/core/router
mkdir -p lib/core/theme lib/core/utils lib/core/widgets lib/core/analytics

for feature in auth job_logging customer_history knowledge_base whatsapp_followup technician_profile; do
  mkdir -p lib/features/$feature/data/datasources
  mkdir -p lib/features/$feature/data/models
  mkdir -p lib/features/$feature/data/repositories
  mkdir -p lib/features/$feature/domain/entities
  mkdir -p lib/features/$feature/domain/repositories
  mkdir -p lib/features/$feature/domain/usecases
  mkdir -p lib/features/$feature/presentation/providers
  mkdir -p lib/features/$feature/presentation/screens
  mkdir -p lib/features/$feature/presentation/widgets
done

mkdir -p test/core/utils test/helpers integration_test
for feature in auth job_logging customer_history knowledge_base whatsapp_followup technician_profile; do
  mkdir -p test/features/$feature/domain/usecases
  mkdir -p test/features/$feature/data/repositories
  mkdir -p test/features/$feature/presentation/widgets
done

---

## 24.4 pubspec.yaml

version: 1.0.0+1 / sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  supabase_flutter: ^2.5.0
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.1.3
  go_router: ^13.2.0
  pinput: ^3.0.1
  image_picker: ^1.1.2
  flutter_image_compress: ^2.2.0
  url_launcher: ^6.2.6
  share_plus: ^9.0.0
  connectivity_plus: ^6.0.3
  intl: ^0.19.0
  uuid: ^4.4.0
  google_fonts: ^6.2.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  riverpod_generator: ^2.4.3
  build_runner: ^2.4.9
  isar_generator: ^3.1.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  flutter_lints: ^4.0.0
  mocktail: ^1.0.3

flutter pub get

---

## 24.5 Build Sequence — 70 Steps Across 10 Phases

PHASE 1 — Foundation (no UI)
  01: Core constants (app, supabase, whatsapp, analytics)
  02: App theme (app_colors, app_spacing, app_text_styles, app_theme)
  03: Supabase initialization
  04: Isar initialization
  05: Run Document 12 SQL in Supabase (extensions→enums→tables→triggers→RLS→functions→storage)
  06: Core providers (supabase, isar, connectivity, auth state)
  07: Core utilities (phone formatter, currency formatter, WhatsApp launcher)
  08: Route names + router scaffold

PHASE 2 — Domain Layer (no UI, no data)
  09: All 6 domain entities
  10: All repository interfaces
  11: Core use case base class

PHASE 3 — Core Widgets (no features)
  12: KsButton (5 variants)
  13: KsTextField (5 types)
  14: KsCard (3 variants)
  15: KsBadge, KsAvatar, KsTagChip, KsDivider
  16: KsAppBar, KsBottomNav, KsScaffoldShell
  17: KsEmptyState, KsLoadingIndicator, KsSkeletonLoader
  18: KsOfflineBanner, KsSnackbar, KsConfirmDialog

PHASE 4 — Auth Feature
  19: Auth remote datasource
  20: Auth repository impl
  21: RequestOTP + VerifyOTP use cases
  22: Auth provider
  23: PhoneEntryScreen + OtpVerifyScreen + OnboardingScreen
  24: Router auth redirect logic
  *** CHECKPOINT 1: OTP login end-to-end on real device ***

PHASE 5 — Job Logging Feature
  25: Job Isar schema
  26: Job remote datasource
  27: Job local datasource
  28: Job repository impl (offline-first)
  29: LogJob + GetJobs + GetJob use cases
  30: Job list provider + log job provider
  31: JobCard + ServiceTypePicker widgets
  32: JobListScreen + LogJobScreen
  33: GoRouter job routes
  *** CHECKPOINT 2: Log job offline, see it in list, sync when online ***

PHASE 6 — WhatsApp Follow-up Feature
  34: FollowUp remote datasource
  35: FollowUp repository impl
  36: BuildMessage + SendFollowUp use cases
  37: FollowUp provider
  38: FollowUpButton + FollowUpMessagePreview widgets
  39: JobDetailScreen
  40: SyncStatusIndicator widget
  *** CHECKPOINT 3: Tap send, WhatsApp opens, button locks, double-send impossible ***

PHASE 7 — Customer History Feature
  41: Customer Isar schema
  42: Customer remote + local datasources
  43: Customer repository impl
  44: Customer use cases (create, get, update, delete)
  45: Customer list + detail providers
  46: CustomerCard + CustomerSearchBar + CustomerJobHistoryList widgets
  47: CustomerListScreen + CustomerDetailScreen + AddCustomerScreen
  48: Customer autocomplete in LogJobScreen

PHASE 8 — Knowledge Base Feature
  49: KnowledgeNote Isar schema
  50: Note remote + local datasources
  51: Note repository impl
  52: Note use cases (create, get, update, archive)
  53: Notes list + detail providers
  54: NoteCard + TagInputField + NoteSearchBar widgets
  55: NotesListScreen + NoteDetailScreen + AddNoteScreen

PHASE 9 — Technician Profile Feature
  56: Profile remote datasource
  57: Profile repository impl
  58: Profile use cases (get, update, share)
  59: Profile provider + PublicProfile provider
  60: ProfileHeader + ShareProfileButton + ServiceChips widgets
  61: ProfileScreen + EditProfileScreen + PublicProfileScreen
  62: Photo upload flow

PHASE 10 — Polish and Production Readiness
  63: Offline banner animations
  64: Skeleton loaders on all list screens
  65: Pull-to-refresh on all list screens
  66: Unsaved changes dialogs on all edit screens
  67: Analytics events (Document 22) — fire-and-forget
  68: Error boundary in app.dart (Document 20)
  69: app_events Supabase table
  70: Pre-release checklist (Document 21)
  *** CHECKPOINT 4: Full smoke test — all 5 features + offline + sync ***

---

## 24.6 Phase 1 File References

Step 01: lib/core/constants/ — paste from Documents 19, 22
Step 02: lib/core/theme/ — paste app_colors.dart + app_spacing.dart from Document 14
Step 05: Supabase SQL editor — Document 12 sections in order (12.1→12.7)
Step 07: lib/core/utils/whatsapp_launcher.dart — paste from Document 19
         lib/core/utils/phone_formatter.dart — implement from Document 10 rules
Step 08: lib/core/router/ — paste route_names.dart + app_router.dart from Document 17

---

## 24.7 Key Rules — Check Before Every File

Architecture (Document 13):
  Presentation never imports from Data
  Domain has zero Flutter imports
  Features never import from each other
  One file = one class = one responsibility

Design (Document 14):
  No hardcoded Color() — always AppColors.*
  No hardcoded padding — always AppSpacing.*
  No hardcoded text styles — always AppTextStyles.*

Data (Document 12):
  Never hard delete — archive or soft delete only
  Always write local before remote
  Always check user_id ownership in queries

Validation (Document 10):
  Validate before any I/O
  Phone normalization at input not display
  Amount: strip commas before parsing

Error (Document 20):
  Analytics calls never throw
  Network failures non-fatal if local save succeeded
  All user messages from Document 20 error reference table

---

## 24.8 The 4 Checkpoints

CHECKPOINT 1 — OTP Login (after Step 24)
  1. Enter real Ghana phone number
  2. Receive real SMS OTP
  3. Enter code → onboarding
  4. Enter name, select services → Job List
  5. Kill and reopen → still logged in
  Pass: all 5 steps work without error

CHECKPOINT 2 — Log Job Offline (after Step 33)
  1. Turn off WiFi and mobile data
  2. Log a job
  3. See job in list with "Saving..." badge
  4. Turn WiFi on
  5. Badge disappears (sync_status = synced)
  Pass: job never disappears, sync completes automatically

CHECKPOINT 3 — WhatsApp Follow-up (after Step 40)
  1. Open a logged job
  2. See FollowUpMessagePreview with correct customer name
  3. Tap "Send WhatsApp Follow-up"
  4. WhatsApp opens with pre-filled message
  5. Return to app
  6. Button shows "Follow-up Sent"
  7. Tap button again — nothing happens
  Pass: all 7 steps work, double-send impossible

CHECKPOINT 4 — Full Flow (after Step 70)
  1. Log in with OTP
  2. Log 3 jobs (one offline, two online)
  3. Send follow-up on one job
  4. Add a customer manually
  5. Search for customer — see job history
  6. Save a knowledge note with 3 tags
  7. Search note by tag — find it
  8. Open profile — share link
  9. Open link in browser — see public profile
  10. Tap WhatsApp CTA — opens WhatsApp chat
  Pass: all 10 steps on physical device

---

## 24.9 Production Launch Sequence

flutter test                              # all tests must pass
flutter analyze                           # zero issues
# increment versionCode and versionName in build.gradle

flutter build apk --flavor prod --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=$PROD_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$PROD_SUPABASE_ANON_KEY \
  --dart-define=APP_NAME="Keystone"

# Test on physical device
adb install build/app/outputs/flutter-apk/app-prod-release.apk
# Run Checkpoint 4 again on production APK

# Send to Jeremie and Jean via WhatsApp
# Walk them through installation (Document 21 section 21.5)

# Upgrade roles in production Supabase
UPDATE users
SET role = 'founding_technician', status = 'active'
WHERE phone_number IN ('+233[jeremie]', '+233[jean]');

# Monitor first 48 hours
# Run Document 22 weekly SQL query daily for first week
# Stay available on WhatsApp

---

## 24.10 Document Quick Reference

01 — What problem are we solving?
03 — What does V1 success look like?
04 — What ships in V1?
05 — Who are Jeremie and Jean?
07 — What are the exact data models?
08 — What are the state machine rules?
09 — Who can do what?
10 — What validation rules apply?
11 — What are the API endpoints?
12 — What SQL do I run in Supabase?
13 — Where does this file go?
14 — What color / font / spacing do I use?
15 — What widget do I use for this?
16 — What does this screen look like?
17 — How does navigation work?
18 — How do I test this?
19 — How do I integrate Africa's Talking?
20 — What error message do I show?
21 — How do I build and deploy?
22 — What do I track?
23 — What comes after V1?
24 — Where do I start?

---

## 24.11 Final Note

This blueprint took 24 documents to write because Keystone deserves to be built right.

Jeremie and Jean are professionals. Their work is skilled, essential, and underserved
by existing tools. Every decision in these 24 documents — from the Supabase RLS policies
to the gold accent color to the founding partner principle — was made with them in mind.

Build it well.

---

## Validation Checklist
- [x] Pre-code reading list specified
- [x] Environment setup with exact version requirements
- [x] Folder creation script matches Document 13
- [x] Complete pubspec.yaml with all dependencies
- [x] 70-step build sequence in dependency order
- [x] Phase 1 detail with file references to source documents
- [x] 7 key rules from architecture, design, data, validation, error documents
- [x] 4 checkpoints with specific pass criteria on physical device
- [x] Production launch sequence with role upgrade SQL
- [x] Quick reference table for all 24 documents
