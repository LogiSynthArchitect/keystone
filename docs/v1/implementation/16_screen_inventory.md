# DOCUMENT 16 — SCREEN INVENTORY
### Project: Keystone
**Status:** APPROVED ✅
**Location:** Ghana, West Africa
**Date:** 2026

---

## 16.1 Screen Index

| # | Screen | Route | Feature |
|---|---|---|---|
| 01 | Phone Entry | /auth/phone | auth |
| 02 | OTP Verify | /auth/otp | auth |
| 03 | Onboarding | /auth/onboarding | auth |
| 04 | Job List | /jobs | job_logging |
| 05 | Log Job Wizard | /jobs/new | job_logging |
| 06 | Job Detail | /jobs/:id | job_logging |
| 07 | Customer List | /customers | customer_history |
| 08 | Customer Detail | /customers/:id | customer_history |
| 09 | Add Customer Wizard | /customers/new | customer_history |
| 10 | Notes List | /notes | knowledge_base |
| 11 | Note Detail | /notes/:id | knowledge_base |
| 12 | Add Note Wizard | /notes/new | knowledge_base |
| 13 | Profile | /profile | technician_profile |
| 14 | Edit Profile | /profile/edit | technician_profile |
| 15 | Public Profile | /p/:slug | technician_profile |
| 16 | Admin Requests | /admin/requests | job_logging |

Total: 16 screens

---

## 16.2 Core Screen Definitions

### Screen 05, 09, 12 — Tactical Wizards
These screens share a unified multi-step architecture to reduce cognitive load in the field.
- **Components:** `StepIndicator`, `AnimatedSwitcher`, `BottomActionBar` (Next/Save toggle).
- **Behavior:** Back button decrements steps before prompting discard.

### Screen 16 — Admin Requests
File: `lib/features/job_logging/presentation/screens/admin_requests_screen.dart`
Route: `/admin/requests`
Purpose: Secured dashboard for admins to approve technician-requested job corrections.
Layout: 
- List of `CorrectionRequestCard` entities.
- Modal dialog for approval (updates job) or rejection (adds notes).

---

## 16.3 Shared Behaviors

- **Haptics:** `mediumImpact` on navigation, `heavyImpact` on data save.
- **Typography:** Monospace Tabular figures for all currency and phone data.
- **Guidance:** Integrated "Field Hints" below input labels.
- **Offline:** All entry screens support full offline operation with Hive caching.
