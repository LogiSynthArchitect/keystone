# KEYSTONE — MASTER DOCUMENT INDEX
### The single entry point for any AI or developer working on this project
**Project:** Keystone — Locksmith Business Management App
**Market:** Ghana, West Africa
**Users:** Jeremie and Jean (founding technicians)
**Stack:** Flutter + Riverpod + Supabase + Hive + GoRouter
**Status:** V1 Polish — UI Redesign and Testing In Progress
**Last Updated:** March 16 2026

---

## HOW TO USE THIS INDEX

If you are an AI starting a new session on this project:
1. Read this file first — it tells you everything that exists
2. Read current_state.md second — it tells you where things stand today
3. Read DIRC_PROTOCOL.md if you are running a domain review
4. Reference any other document by number when you need detail

If you are a developer starting a new session:
1. Read current_state.md — it tells you exactly what to do next
2. Reference documents by number as needed

---

## WHAT KEYSTONE IS

A mobile-first business management tool for independent locksmith technicians in Ghana.
It allows technicians to log jobs, manage customer history, save technical knowledge,
send WhatsApp follow-ups, and share a professional profile — all from their phone.

V1 users: Jeremie and Jean only.
V1 platform: Android only.
V1 distribution: Direct APK via WhatsApp.

---

## DOCUMENT REGISTRY

### Problem Layer — Why this exists

| # | File | What it answers |
|---|---|---|
| 01 | docs/v1/problem/01_problem_brief.md | What problem are we solving? Who has it? Why does it matter? |
| 02 | docs/v1/problem/02_market_research.md | Who are the competitors? What is the market size? What are the gaps? |
| 03 | docs/v1/problem/03_core_hypothesis.md | What must V1 prove? What does success look like? What are the failure conditions? |
| 05 | docs/v1/problem/05_user_personas.md | Who are Jeremie and Jean? What do they need? What will make them churn? |

### Systems Layer — How it works

| # | File | What it answers |
|---|---|---|
| 04 | docs/v1/systems/04_core_scope.md | What features ship in V1? What is explicitly excluded? |
| 06 | docs/v1/systems/06_user_flows.md | How does a user move through the app? |
| 08 | docs/v1/systems/08_state_machines.md | What states can each entity be in? |
| 09 | docs/v1/systems/09_permission_matrix.md | Who can do what? |
| 13 | docs/v1/systems/13_flutter_architecture.md | Where does every file go? What layer talks to what? |
| 17 | docs/v1/systems/17_navigation_architecture.md | How does GoRouter work? |
| 19 | docs/v1/systems/19_integrations.md | How does Supabase, Africa's Talking, WhatsApp deep link work? |

### Data Layer — What it stores

| # | File | What it answers |
|---|---|---|
| 07 | docs/v1/models/07_domain_model.md | What are the 6 entities? What fields do they have? |
| 10 | docs/v1/models/10_validation_rules.md | What validation applies to every field? |
| 11 | docs/v1/models/11_api_contracts.md | What are the exact API endpoints? |
| 12 | docs/v1/models/12_database_schema.md | What SQL creates the database? |

### Design Layer — What it looks like

| # | File | What it answers |
|---|---|---|
| 14 | docs/v1/design/14_design_system.md | What are the colors, fonts, spacing, and component specs? |
| 15 | docs/v1/implementation/15_component_inventory.md | What widgets exist? |
| 16 | docs/v1/implementation/16_screen_inventory.md | What are the 15 screens? |

### Implementation Layer — How to build it

| # | File | What it answers |
|---|---|---|
| 20 | docs/v1/implementation/20_error_handling.md | What error classes exist? What message does every error show? |
| 21 | docs/v1/implementation/21_deployment_strategy.md | How do you build the APK? |
| 24 | docs/v1/implementation/24_implementation_guide.md | What is the 70-step build sequence? |
| 25 | docs/v1/implementation/25_v1_polish.md | What UI redesign is in progress? What screens are done? |

### Tracking Layer — What has happened

| File | What it answers |
|---|---|
| docs/v1/tracking/current_state.md | What is the exact state of the project right now? |
| docs/v1/tracking/dev_log.md | What was built in each session? What broke? What was learned? |
| docs/v1/tracking/DIAGNOSTIC_MANUAL.md | What are the known bugs and their fixes? |
| docs/v1/tracking/22_monitoring_analytics.md | What events are tracked? |
| docs/dirc/DIRC_PROTOCOL.md | How do you run a Domain Integrity Review? |
| docs/patterns.md | What cross-project lessons have been learned? |
| docs/dirc_log.md | What domain reviews have been run and what were the results? |

### Roadmap Layer — Where it is going

| # | File | What it answers |
|---|---|---|
| 23 | docs/v1/roadmap/23_product_roadmap.md | What are V1 V2 V3 V4? What triggers each phase? |

### Migration Layer — How the code was restructured

| File | What it answers |
|---|---|
| docs/v1/migration/migration_plan.md | What was the migration plan? |
| docs/v1/migration/project_map.md | What is every file in lib/? |

---

## QUICK REFERENCE

**Where does this file go?** → Document 13 — Section 13.2
**What color do I use?** → Document 14 — AppColors
**What widget do I use for this?** → Document 15 — Component Inventory
**What does this screen look like?** → Document 16 — Screen Inventory
**What error message do I show?** → Document 20 — Sections 20.8 to 20.11
**What SQL do I run in Supabase?** → Document 12 — Section 12.8
**How does navigation work?** → Document 17
**What validation applies?** → Document 10
**What is the state machine?** → Document 08
**Who can do this action?** → Document 09
**How do I build the APK?** → Document 21 — Section 21.4
**What is the WhatsApp template?** → Document 19 — Section 19.4
**What broke before and how was it fixed?** → docs/v1/tracking/DIAGNOSTIC_MANUAL.md
**What is the current build status?** → docs/v1/tracking/current_state.md

---

## ARCHITECTURE IN ONE PARAGRAPH

Keystone is a Flutter app using Clean Architecture with a feature-first folder structure.
Each of the 6 features — auth, job_logging, customer_history, knowledge_base,
whatsapp_followup, technician_profile — contains its own data, domain, and presentation
layers. Features never import each other directly — they communicate through
lib/core/providers/shared_feature_providers.dart. State management is Riverpod.
Backend is Supabase. Local storage is Hive for offline-first operation. Navigation
is GoRouter with auth-guarded redirects. The design system uses Barlow Semi Condensed
typography, AppColors.primary900 deep navy and AppColors.accent500 warm gold.

---

## THE 6 FEATURES

| Feature | Folder | Purpose |
|---|---|---|
| Auth | lib/features/auth/ | Phone OTP login, onboarding, session management |
| Job Logging | lib/features/job_logging/ | Log a completed job in under 60 seconds |
| Customer History | lib/features/customer_history/ | Search and view all jobs per customer |
| Knowledge Base | lib/features/knowledge_base/ | Save and search technical solutions |
| WhatsApp Follow-up | lib/features/whatsapp_followup/ | Send professional follow-up via WhatsApp |
| Technician Profile | lib/features/technician_profile/ | Shareable public profile page |

---

## THE 15 SCREENS

| # | Screen | Route | Status |
|---|---|---|---|
| 01 | Phone Entry | /auth/phone | Done |
| 02 | OTP Verify | /auth/otp | Done |
| 03 | Onboarding | /auth/onboarding | Done |
| 04 | Job List | /jobs | Done |
| 05 | Log Job | /jobs/new | Done |
| 06 | Job Detail | /jobs/:id | Done |
| 07 | Customer List | /customers | Done |
| 08 | Customer Detail | /customers/:id | Pending |
| 09 | Add Customer | /customers/new | Done |
| 10 | Notes List | /notes | Done |
| 11 | Note Detail | /notes/:id | Pending |
| 12 | Add Note | /notes/new | Done |
| 13 | Profile | /profile | Pending |
| 14 | Edit Profile | /profile/edit | Done |
| 15 | Public Profile | /p/:slug | Done |

---

## TEST STATUS

| File | Tests | Status |
|---|---|---|
| test/helpers/mocks.dart | 9 mock classes | Done |
| test/features/job_logging/domain/usecases/log_job_usecase_test.dart | 8 tests | Passing |
| test/features/whatsapp_followup/domain/usecases/send_followup_usecase_test.dart | 4 tests | Passing |
| test/core/utils/phone_formatter_test.dart | Not written yet | Pending |
| integration_test/log_job_flow_test.dart | Not written yet | Pending |
| integration_test/offline_sync_flow_test.dart | Not written yet | Pending |

Total: 12 tests passing

---

## FOUNDING PRINCIPLE

Jeremie and Jean are not just users. They are founding partners.
Every decision in this codebase was made with them in mind.
Build it well.
