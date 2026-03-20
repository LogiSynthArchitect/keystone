# KEYSTONE — MASTER DOCUMENT INDEX
### The single entry point for any AI or developer working on this project
**Project:** Keystone — Locksmith Job Management App
**Market:** Ghana, West Africa
**Users:** Jeremie and Jean (Pilot Users)
**Status:** V1 COMPLETE — Session 29 ✅
**Last Updated:** March 20, 2026

---

## 1. TRACKING (START HERE)

| File | Purpose |
|---|---|
| docs/v1/tracking/current_state.md | Current build status and V1 readiness. |
| docs/v1/tracking/dev_log.md | Chronological record of sessions and fixes. |
| docs/v1/tracking/admin_runbook.md | Procedures for system administration. |
| docs/v1/tracking/query_standards.md | SQL standards for WhatsApp data. |
| docs/dirc_log.md | Record of all Domain Integrity Review Cycles. |
| docs/patterns.md | Cross-project lessons and architectural patterns. |

---

## 2. BLUEPRINTS (HOW IT'S BUILT)

### Systems Layer
| # | File | Purpose |
|---|---|---|
| 04 | docs/v1/systems/04_core_scope.md | V1 Feature boundaries. |
| 06 | docs/v1/systems/06_user_flows.md | Tactical Wizard and Admin flows. |
| 08 | docs/v1/systems/08_state_machines.md | Sync, Lock, and Correction lifecycles. |
| 09 | docs/v1/systems/09_permission_matrix.md | Role-based access control (Admin/Founding). |
| 13 | docs/v1/systems/13_flutter_architecture.md | Clean Architecture & Feature-First structure. |

### Data Layer
| # | File | Purpose |
|---|---|---|
| 07 | docs/v1/models/07_domain_model.md | The 7 Core Entities (User to CorrectionRequest). |
| 10 | docs/v1/models/10_validation_rules.md | Field-level validation constraints. |
| 12 | docs/v1/models/12_database_schema.md | Supabase Tables, Triggers, and RLS Policies. |

### Design & UI
| # | File | Purpose |
|---|---|---|
| 14 | docs/v1/design/14_design_system.md | Dark Industrial specs. |
| 16 | docs/v1/implementation/16_screen_inventory.md | The 16 core screens. |
| 25 | docs/v1/implementation/25_v1_polish.md | Final redesign and feature completion log. |

---

## 3. VERIFICATION

- **Automated Tests:** 80 PASSING / 0 FAILING.
- **Coverage:** Unit (Domain), Widget (Wizards), and Integration (Offline Sync).
- **DIRC Status:** DIRC-004 PASS ✅.
- **Open Bugs:** 0 (BUG-001 through BUG-031 all closed as of Session 29).

---

## 4. ARCHITECTURE OVERVIEW

Keystone is an **offline-first job management app** built using Flutter and Clean Architecture.
- **State:** Riverpod.
- **Storage:** Hive (Local) + Supabase (Remote).
- **Mobile UI:** Dark Industrial theme, monospace typography, haptic feedback.
- **Web UI:** Light theme (public profile pages only) with actual Keystone SVG logo.
- **Bridge:** Features are isolated and communicate only via `lib/core/providers/shared_feature_providers.dart`.
- **Theme:** Full light/dark mode via KsColors ThemeExtension. Always use `context.ksc.*` in widget code.
