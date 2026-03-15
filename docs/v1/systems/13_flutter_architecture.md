# DOCUMENT 13 — FLUTTER ARCHITECTURE
### Project: Keystone
**Required Inputs:** Document 04 — Core Scope, Document 07 — Domain Model, Document 12 — Database Schema
**Framework:** Flutter + Riverpod + Clean Architecture
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 13.1 Architecture Principles

Rule 1 — Unidirectional dependency: Presentation → Domain → Data
Rule 2 — Domain is pure Dart: zero Flutter imports in any domain file
Rule 3 — One file, one class, one responsibility
Rule 4 — Features never import each other — communicate through core/ only
Rule 5 — All external dependencies are injected via Riverpod

---

## 13.2 Complete Folder Structure

lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── supabase_constants.dart
│   │   └── whatsapp_constants.dart
│   ├── errors/
│   │   ├── app_exception.dart
│   │   ├── auth_exception.dart
│   │   ├── network_exception.dart
│   │   └── validation_exception.dart
│   ├── network/
│   │   ├── supabase_client.dart
│   │   └── connectivity_service.dart
│   ├── storage/
│   │   ├── isar_service.dart
│   │   └── isar_schemas/
│   │       ├── job_isar_schema.dart
│   │       ├── customer_isar_schema.dart
│   │       └── knowledge_note_isar_schema.dart
│   ├── providers/
│   │   ├── supabase_provider.dart
│   │   ├── isar_provider.dart
│   │   ├── connectivity_provider.dart
│   │   └── auth_provider.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_spacing.dart
│   └── utils/
│       ├── phone_formatter.dart
│       ├── currency_formatter.dart
│       ├── date_formatter.dart
│       ├── slug_generator.dart
│       └── whatsapp_launcher.dart
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/auth_remote_datasource.dart
    │   │   ├── models/auth_response_model.dart
    │   │   └── repositories/auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/auth_user.dart
    │   │   ├── repositories/auth_repository.dart
    │   │   └── usecases/
    │   │       ├── request_otp_usecase.dart
    │   │       ├── verify_otp_usecase.dart
    │   │       └── logout_usecase.dart
    │   └── presentation/
    │       ├── providers/auth_provider.dart
    │       ├── screens/
    │       │   ├── phone_entry_screen.dart
    │       │   ├── otp_verify_screen.dart
    │       │   └── onboarding_screen.dart
    │       └── widgets/
    │           ├── phone_input_field.dart
    │           └── otp_input_field.dart
    │
    ├── job_logging/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── job_remote_datasource.dart
    │   │   │   └── job_local_datasource.dart
    │   │   ├── models/job_model.dart
    │   │   └── repositories/job_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/job.dart
    │   │   ├── repositories/job_repository.dart
    │   │   └── usecases/
    │   │       ├── log_job_usecase.dart
    │   │       ├── get_jobs_usecase.dart
    │   │       ├── get_job_usecase.dart
    │   │       ├── update_job_usecase.dart
    │   │       └── sync_offline_jobs_usecase.dart
    │   └── presentation/
    │       ├── providers/
    │       │   ├── job_list_provider.dart
    │       │   └── log_job_provider.dart
    │       ├── screens/
    │       │   ├── job_list_screen.dart
    │       │   ├── log_job_screen.dart
    │       │   └── job_detail_screen.dart
    │       └── widgets/
    │           ├── job_card.dart
    │           ├── service_type_picker.dart
    │           └── amount_input_field.dart
    │
    ├── customer_history/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── customer_remote_datasource.dart
    │   │   │   └── customer_local_datasource.dart
    │   │   ├── models/customer_model.dart
    │   │   └── repositories/customer_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/customer.dart
    │   │   ├── repositories/customer_repository.dart
    │   │   └── usecases/
    │   │       ├── create_customer_usecase.dart
    │   │       ├── get_customers_usecase.dart
    │   │       ├── get_customer_usecase.dart
    │   │       ├── update_customer_usecase.dart
    │   │       └── delete_customer_usecase.dart
    │   └── presentation/
    │       ├── providers/
    │       │   ├── customer_list_provider.dart
    │       │   └── customer_detail_provider.dart
    │       ├── screens/
    │       │   ├── customer_list_screen.dart
    │       │   ├── customer_detail_screen.dart
    │       │   └── add_customer_screen.dart
    │       └── widgets/
    │           ├── customer_card.dart
    │           ├── customer_search_bar.dart
    │           └── customer_job_history_list.dart
    │
    ├── knowledge_base/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── knowledge_note_remote_datasource.dart
    │   │   │   └── knowledge_note_local_datasource.dart
    │   │   ├── models/knowledge_note_model.dart
    │   │   └── repositories/knowledge_note_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/knowledge_note.dart
    │   │   ├── repositories/knowledge_note_repository.dart
    │   │   └── usecases/
    │   │       ├── create_note_usecase.dart
    │   │       ├── get_notes_usecase.dart
    │   │       ├── get_note_usecase.dart
    │   │       ├── update_note_usecase.dart
    │   │       └── archive_note_usecase.dart
    │   └── presentation/
    │       ├── providers/
    │       │   ├── notes_list_provider.dart
    │       │   └── note_detail_provider.dart
    │       ├── screens/
    │       │   ├── notes_list_screen.dart
    │       │   ├── note_detail_screen.dart
    │       │   └── add_note_screen.dart
    │       └── widgets/
    │           ├── note_card.dart
    │           ├── tag_input_field.dart
    │           └── note_search_bar.dart
    │
    ├── whatsapp_followup/
    │   ├── data/
    │   │   ├── datasources/followup_remote_datasource.dart
    │   │   ├── models/followup_model.dart
    │   │   └── repositories/followup_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/follow_up.dart
    │   │   ├── repositories/followup_repository.dart
    │   │   └── usecases/
    │   │       ├── send_followup_usecase.dart
    │   │       └── build_followup_message_usecase.dart
    │   └── presentation/
    │       ├── providers/followup_provider.dart
    │       └── widgets/
    │           ├── followup_button.dart
    │           └── followup_message_preview.dart
    │
    └── technician_profile/
        ├── data/
        │   ├── datasources/profile_remote_datasource.dart
        │   ├── models/profile_model.dart
        │   └── repositories/profile_repository_impl.dart
        ├── domain/
        │   ├── entities/profile.dart
        │   ├── repositories/profile_repository.dart
        │   └── usecases/
        │       ├── get_profile_usecase.dart
        │       ├── update_profile_usecase.dart
        │       └── share_profile_usecase.dart
        └── presentation/
            ├── providers/profile_provider.dart
            ├── screens/
            │   ├── profile_screen.dart
            │   └── edit_profile_screen.dart
            └── widgets/
                ├── profile_header.dart
                ├── service_chips.dart
                └── share_profile_button.dart

---

## 13.3 Layer Responsibilities

Data Layer:
- datasources/ — all external I/O (Supabase + Isar). Returns raw Maps or throws NetworkException/StorageException.
- models/ — DTOs with fromJson(), toJson(), fromIsar(), toIsar(). No business logic.
- repositories/ — implements domain interface. Decides local vs remote. Maps models to entities.

Domain Layer:
- entities/ — pure Dart, immutable, final fields only, no fromJson
- repositories/ — abstract interfaces only, no implementation
- usecases/ — single call() method, one responsibility, contains all business rules

Presentation Layer:
- providers/ — Riverpod AsyncNotifier/Notifier. Calls usecases only. Manages loading/error/data.
- screens/ — full-page widgets. Reads providers. Layout only, no business logic.
- widgets/ — reusable components. Stateless where possible. Emit callbacks upward.

---

## 13.4 Dependency Injection via Riverpod

Chain: supabaseClientProvider → *RemoteDatasourceProvider → *RepositoryProvider → *UsecaseProvider → AsyncNotifierProvider

All dependencies defined in core/providers/ and injected top-down.
Features never instantiate their own dependencies.

---

## 13.5 Offline-First Data Flow

READ:
1. Return local data immediately (instant UI)
2. If online, fetch remote in background
3. Update local with remote data
4. Notify UI of update

WRITE:
1. Write to local first (never block on network)
2. If online, sync to remote immediately
3. If offline, mark sync_status = pending
4. Background sync picks up pending records when connectivity returns

---

## 13.6 Error Handling Pattern

Data layer throws:    NetworkException, StorageException
Domain layer throws:  DomainException (wraps data exceptions)
Presentation catches: DomainException → displays user-friendly message

Use AsyncValue.guard() in all providers.
Widgets check state.hasError and display message from exception.code.

---

## 13.7 Key Dependencies

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

dev:
riverpod_generator: ^2.4.3
build_runner: ^2.4.9
isar_generator: ^3.1.0
flutter_lints: ^4.0.0
mocktail: ^1.0.3

---

## 13.8 main.dart Initialization Order

1. WidgetsFlutterBinding.ensureInitialized()
2. Supabase.initialize(url, anonKey)
3. IsarService.initialize()
4. runApp(ProviderScope(overrides: [isarProvider.overrideWithValue(isar)], child: KeystoneApp()))

---

## 13.9 Naming Conventions

Files:      snake_case               log_job_usecase.dart
Classes:    PascalCase               LogJobUsecase
Variables:  camelCase                jobDate
Providers:  camelCase + Provider     jobRepositoryProvider
Notifiers:  PascalCase + Notifier    LogJobNotifier
Screens:    PascalCase + Screen      LogJobScreen
Widgets:    PascalCase               JobCard
Routes:     /kebab-case              /log-job

---

## 13.10 What Goes Where

Phone normalization:          core/utils/phone_formatter.dart
GHS formatting:               core/utils/currency_formatter.dart
WhatsApp URL building:        core/utils/whatsapp_launcher.dart
Offline sync logic:           job_logging/data/repositories/job_repository_impl.dart
Job field lock validation:    job_logging/domain/usecases/update_job_usecase.dart
Follow-up immutability:       whatsapp_followup/domain/usecases/send_followup_usecase.dart
Current user state:           core/providers/auth_provider.dart
Connectivity state:           core/providers/connectivity_provider.dart
Route guards:                 core/router/app_router.dart
Supabase credentials:         core/constants/supabase_constants.dart

---

## Validation Checklist
- [x] All 5 V1 features have complete feature folders
- [x] All 6 domain entities have entity files
- [x] Clean Architecture layers enforced with dependency rules
- [x] Riverpod DI chain fully defined from client to UI
- [x] Offline-first data flow documented
- [x] Error handling pattern defined for all layers
- [x] All key dependencies listed with versions
- [x] main.dart initialization order documented
- [x] Naming conventions defined for entire codebase
- [x] Quick reference resolves all placement ambiguities
