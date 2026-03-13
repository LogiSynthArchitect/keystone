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
