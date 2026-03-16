# Migration Plan — Keystone

Based on project_map.md.
This is the blueprint for migrating lib/ 
to a feature-first modular architecture.
Do not execute anything. This is planning only.

---

## Target Structure

lib/
├── main.dart
├── app.dart
├── core/
│   ├── analytics/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── providers/
│   ├── storage/
│   ├── theme/
│   ├── usecases/
│   ├── utils/
│   └── widgets/
└── features/
    └── [feature]/
        ├── data/
        │   ├── models/
        │   ├── repositories/
        │   └── datasources/
        ├── domain/
        │   ├── entities/
        │   └── usecases/
        └── presentation/
            ├── screens/
            ├── widgets/
            └── providers/

test/
├── unit/
│   └── [feature]/
├── integration/
│   └── [feature]/
└── e2e/
    └── full_journey/

---

## Features Identified

### 1. Auth
- **Current files:** 19 files across data, domain, and presentation.
- **Move strategy:** Already follows the directory pattern. Requires audit of imports to ensure no direct sibling imports (e.g., Auth should not import from Profile directly; use `shared_feature_providers`).
- **Special handling:** `auth_notifier.dart` currently imports `ProfileRepository` and `ProfileEntity`. This logic should be moved to a higher-level coordinator or use the shared provider bridge.

### 2. Customer History
- **Current files:** 16 files.
- **Move strategy:** Already follows the directory pattern. 
- **Special handling:** `customer_repository_impl.dart` depends on `job_local_datasource.dart` for cascading ID changes. This is a cross-feature dependency that should be handled via a service or shared logic.

### 3. Job Logging
- **Current files:** 16 files.
- **Move strategy:** Already follows the directory pattern.
- **Special handling:** Depends on `CustomerLocalDatasource` and `FollowUpRepository`. These dependencies must be routed through the `shared_feature_providers.dart` bridge to maintain modularity.

### 4. Knowledge Base
- **Current files:** 14 files.
- **Move strategy:** Stays in current folder. Cleanest isolation.
- **Special handling:** None. This is the safest candidate for the first migration step.

### 5. Technician Profile
- **Current files:** 13 files.
- **Move strategy:** Stays in current folder.
- **Special handling:** Foundation for the Public Profile and Follow-up features.

### 6. Whatsapp Followup
- **Current files:** 13 files.
- **Move strategy:** Already follows the directory pattern.
- **Special handling:** High coupling. Depends on `job_providers.dart`, `customer_providers.dart`, and `profile_provider.dart`.

---

## Core Files

| File | Current Location | Target Location | Status |
| --- | --- | --- | --- |
| `analytics_constants.dart` | `lib/core/analytics/` | `lib/core/analytics/` | Stays |
| `ks_analytics.dart` | `lib/core/analytics/` | `lib/core/analytics/` | Stays |
| `app_constants.dart` | `lib/core/constants/` | `lib/core/constants/` | Stays |
| `app_enums.dart` | `lib/core/constants/` | `lib/core/constants/` | Stays |
| `supabase_constants.dart` | `lib/core/constants/` | `lib/core/constants/` | Stays |
| `whatsapp_constants.dart` | `lib/core/constants/` | `lib/core/constants/` | Stays |
| `app_exception.dart` | `lib/core/errors/` | `lib/core/errors/` | Stays |
| `auth_exception.dart` | `lib/core/errors/` | `lib/core/errors/` | Stays |
| `network_exception.dart` | `lib/core/errors/` | `lib/core/errors/` | Stays |
| `storage_exception.dart` | `lib/core/errors/` | `lib/core/errors/` | Stays |
| `validation_exception.dart` | `lib/core/errors/` | `lib/core/errors/` | Stays |
| `connectivity_service.dart` | `lib/core/network/` | `lib/core/network/` | Stays |
| `supabase_client.dart` | `lib/core/network/` | `lib/core/network/` | Stays |
| `auth_provider.dart` | `lib/core/providers/` | `lib/core/providers/` | Stays |
| `connectivity_provider.dart` | `lib/core/providers/` | `lib/core/providers/` | Stays |
| `shared_feature_providers.dart` | `lib/core/providers/` | `lib/core/providers/` | Stays |
| `supabase_provider.dart` | `lib/core/providers/` | `lib/core/providers/` | Stays |
| `app_router.dart` | `lib/core/router/` | `lib/core/router/` | Stays |
| `route_names.dart` | `lib/core/router/` | `lib/core/router/` | Stays |
| `hive_service.dart` | `lib/core/storage/` | `lib/core/storage/` | Stays |
| `app_colors.dart` | `lib/core/theme/` | `lib/core/theme/` | Stays |
| `app_spacing.dart` | `lib/core/theme/` | `lib/core/theme/` | Stays |
| `app_text_styles.dart` | `lib/core/theme/` | `lib/core/theme/` | Stays |
| `app_theme.dart` | `lib/core/theme/` | `lib/core/theme/` | Stays |
| `use_case.dart` | `lib/core/usecases/` | `lib/core/usecases/` | Stays |
| `currency_formatter.dart` | `lib/core/utils/` | `lib/core/utils/` | Stays |
| `date_formatter.dart` | `lib/core/utils/` | `lib/core/utils/` | Stays |
| `phone_formatter.dart` | `lib/core/utils/` | `lib/core/utils/` | Stays |
| `slug_generator.dart` | `lib/core/utils/` | `lib/core/utils/` | Stays |
| `whatsapp_launcher.dart` | `lib/core/utils/` | `lib/core/utils/` | Stays |
| `ks_widgets...` | `lib/core/widgets/` | `lib/core/widgets/` | Stays |

---

## Migration Order

1. **Knowledge Base**: Most isolated. Zero dependencies on other features. High success rate for initial modularization.
2. **Technician Profile**: Foundational for UI but logic is self-contained.
3. **Customer History**: Must be migrated before Jobs, as Jobs rely on Customer IDs.
4. **Job Logging**: Central feature. Depends on Customer History.
5. **Whatsapp Followup**: High dependency on Jobs and Customers. Migrate once parents are stable.
6. **Auth**: Deeply cross-cutting. Affects Router and Session persistence. Best saved for last to ensure feature redirection logic is solid.

---

## Risk Register

- **`shared_feature_providers.dart`**: Any change here ripples through all features. This file must be guarded.
- **Cross-Feature Repositories**: `JobRepository` and `CustomerRepository` have implementation-level dependencies on each other's data sources. 
- **Router Coupling**: `app_router.dart` imports screens from all features. Moving screens requires immediate router updates to prevent build breaks.
- **`AppEnums`**: `ServiceType` is used in 5 out of 6 features. Changes to this enum require a full-project rebuild.

---

## Test Folder Plan

### 1. Auth
- `test/unit/auth/`: `auth_notifier_test.dart`, `request_otp_usecase_test.dart`
- `test/integration/auth/`: `auth_repository_test.dart`

### 2. Customer History
- `test/unit/customer_history/`: `create_customer_usecase_test.dart`
- `test/integration/customer_history/`: `customer_sync_test.dart`

### 3. Job Logging
- `test/unit/job_logging/`: `log_job_usecase_test.dart`
- `test/integration/job_logging/`: `job_repository_sync_test.dart`

### 4. Knowledge Base
- `test/unit/knowledge_base/`: `create_note_usecase_test.dart`
- `test/integration/knowledge_base/`: `knowledge_remote_test.dart`

### 5. Technician Profile
- `test/unit/technician_profile/`: `update_profile_usecase_test.dart`
- `test/integration/technician_profile/`: `photo_upload_test.dart`

### 6. Whatsapp Followup
- `test/unit/whatsapp_followup/`: `message_builder_test.dart`
- `test/integration/whatsapp_followup/`: `follow_up_repository_test.dart`
