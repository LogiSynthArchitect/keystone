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
