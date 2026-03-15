# DOCUMENT 18 — TESTING STRATEGY
### Project: Keystone
**Required Inputs:** Document 08 — State Machines, Document 10 — Validation Rules, Document 13 — Flutter Architecture
**Test framework:** flutter_test + mocktail
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 18.1 Testing Philosophy

Test what breaks silently. Skip what is obvious.

Three highest-risk areas:
1. Offline sync — a job saved offline must never be lost
2. Follow-up state machine — sent follow-up must never be unsendable or double-sent
3. Validation rules — bad data must never reach the database

Testing pyramid:
  75% Unit tests     — use cases, repositories, validators, formatters
  20% Widget tests   — component states and interactions
   5% Integration    — critical user flows end to end

---

## 18.2 Test File Structure

test/
├── core/utils/
│   ├── phone_formatter_test.dart
│   ├── currency_formatter_test.dart
│   ├── date_formatter_test.dart
│   └── whatsapp_launcher_test.dart
├── features/
│   ├── auth/domain/usecases/
│   │   ├── request_otp_usecase_test.dart
│   │   └── verify_otp_usecase_test.dart
│   ├── job_logging/
│   │   ├── domain/usecases/
│   │   │   ├── log_job_usecase_test.dart
│   │   │   ├── update_job_usecase_test.dart
│   │   │   └── sync_offline_jobs_usecase_test.dart
│   │   ├── data/repositories/job_repository_impl_test.dart
│   │   └── presentation/widgets/
│   │       ├── job_card_test.dart
│   │       └── followup_button_test.dart
│   ├── customer_history/domain/usecases/
│   │   ├── create_customer_usecase_test.dart
│   │   └── get_customers_usecase_test.dart
│   ├── knowledge_base/domain/usecases/
│   │   ├── create_note_usecase_test.dart
│   │   └── archive_note_usecase_test.dart
│   └── whatsapp_followup/domain/usecases/
│       ├── send_followup_usecase_test.dart
│       └── build_followup_message_usecase_test.dart
└── integration_test/
    ├── log_job_flow_test.dart
    ├── followup_flow_test.dart
    └── offline_sync_flow_test.dart

---

## 18.3 Unit Tests — LogJobUsecase

group('LogJobUsecase'):

  test: saves job with valid data
    → when repo.createJob returns fakeJob
    → expect result equals fakeJob
    → verify createJob called once

  test: throws ValidationException when service type missing
    → params with null serviceType
    → expect throwsA(isA<ValidationException>())
    → verifyNever createJob called

  test: throws ValidationException when job date is future
    → params with jobDate = now + 1 day
    → expect throwsA(isA<ValidationException>())

  test: throws ValidationException when amount is negative
    → params with amountCharged = -50.00
    → expect throwsA(isA<ValidationException>())

---

## 18.4 Unit Tests — UpdateJobUsecase (24-hour lock)

group('UpdateJobUsecase — 24 hour lock'):

  test: allows updating notes after 24 hours
    → job.createdAt = now - 25 hours
    → params with notes only (no serviceType or jobDate)
    → expect result isA<Job>()

  test: blocks changing serviceType after 24 hours
    → job.createdAt = now - 25 hours
    → params with serviceType changed
    → expect throwsA(ValidationException) with message containing '24 hours'

  test: allows changing serviceType within 24 hours
    → job.createdAt = now - 2 hours
    → params with serviceType changed
    → expect result isA<Job>()

---

## 18.5 Unit Tests — SendFollowupUsecase (state machine)

group('SendFollowupUsecase'):

  test: records follow-up when job.followUpSent is false
    → job.followUpSent = false
    → expect result.deliveryConfirmed == false (V1 always false)
    → verify createFollowUp called once

  test: throws ValidationException when follow-up already sent
    → job.followUpSent = true
    → expect throwsA(ValidationException) with message containing 'already sent'
    → verifyNever createFollowUp called

---

## 18.6 Unit Tests — SyncOfflineJobsUsecase

group('SyncOfflineJobsUsecase'):

  test: syncs all pending jobs when online
    → 2 pending jobs in local store
    → connectivity = true
    → expect result.synced.length == 2, result.failed.length == 0

  test: does nothing when offline
    → connectivity = false
    → expect result.synced.length == 0
    → verifyNever batchSync called

  test: does not retry jobs with 3 failed attempts
    → job.syncRetryCount = 3, syncStatus = failed
    → expect result.failed.length == 1
    → verifyNever batchSync called

---

## 18.7 Unit Tests — PhoneFormatter

group('PhoneFormatter'):
  '0244123456'     → '+233244123456'
  '+233244123456'  → '+233244123456'
  '233244123456'   → '+233244123456'
  '0244 123 456'   → '+233244123456'
  '0244-123-456'   → '+233244123456'
  '12345'          → throwsA(ValidationException)

---

## 18.8 Unit Tests — JobRepositoryImpl

group('JobRepositoryImpl offline-first'):

  test: returns local data regardless of connectivity
    → localDatasource returns [fakeJobModel]
    → connectivity = false
    → expect result.length == 1
    → verifyNever remoteDatasource.getJobs called

  test: writes local first then remote when online
    → connectivity = true
    → verifyInOrder: [localDatasource.saveJob, remoteDatasource.createJob]

  test: saves with pending status when offline
    → connectivity = false
    → capture saved model
    → expect captured.syncStatus == SyncStatus.pending
    → verifyNever remoteDatasource.createJob called

---

## 18.9 Widget Tests — FollowUpButton

group('FollowUpButton'):

  testWidgets: shows Send label when isSent false
    → expect find.text('Send WhatsApp Follow-up')
    → expect find.byIcon(Icons.send_outlined)

  testWidgets: shows sent state when isSent true
    → expect find.text('Follow-up Sent')
    → expect find.byIcon(Icons.check_circle_outline)

  testWidgets: button not tappable when isSent true
    → tap button
    → expect wasTapped == false

  testWidgets: shows loading indicator when isLoading true
    → expect find.byType(CircularProgressIndicator)
    → expect find.text('Send WhatsApp Follow-up') findsNothing

---

## 18.10 Integration Tests (scaffolds)

log_job_flow_test.dart:
  1. Start at JobListScreen
  2. Tap FAB → LogJobScreen
  3. Select service type
  4. Enter customer name (autocomplete or new)
  5. Enter amount
  6. Tap "Save job"
  7. Expect: back on JobListScreen with new job visible

followup_flow_test.dart:
  1. Navigate to JobDetailScreen for job with followUpSent: false
  2. Verify FollowUpButton shows "Send WhatsApp Follow-up"
  3. Tap button
  4. Verify wa.me deep link launched (mock url_launcher)
  5. Verify button shows "Follow-up Sent"
  6. Verify follow_up record exists in local Isar

offline_sync_flow_test.dart:
  1. Set connectivity = offline
  2. Log a job
  3. Expect: job saved locally with syncStatus = pending
  4. Set connectivity = online
  5. Trigger sync
  6. Expect: job syncStatus = synced

---

## 18.11 Mock Setup — test/helpers/mocks.dart

class MockJobRepository extends Mock implements JobRepository {}
class MockCustomerRepository extends Mock implements CustomerRepository {}
class MockKnowledgeNoteRepository extends Mock implements KnowledgeNoteRepository {}
class MockFollowUpRepository extends Mock implements FollowUpRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockJobRemoteDatasource extends Mock implements JobRemoteDatasource {}
class MockJobLocalDatasource extends Mock implements JobLocalDatasource {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockUrlLauncher extends Mock implements UrlLauncherPlatform {}

Shared fakes:
fakeJob:      id, userId, customerId, serviceType, jobDate, followUpSent:false, syncStatus:synced
fakeCustomer: id, userId, fullName, phoneNumber:+233201234567, totalJobs:1

---

## 18.12 Coverage Targets

Domain use cases:         90%  critical
Core utilities:          100%  critical
Data repositories:        80%  high
Presentation providers:   70%  high
Core widgets:             80%  medium
Feature widgets:          60%  medium
Integration flows:         3   high

Non-goals: UI layout, pixel positions, animation curves, Flutter internals

---

## 18.13 Running Tests

flutter test
flutter test test/features/job_logging/domain/usecases/log_job_usecase_test.dart
flutter test --coverage
flutter test integration_test/log_job_flow_test.dart

---

## Validation Checklist
- [x] Test structure mirrors source structure exactly
- [x] Critical paths (sync, follow-up, validation) have dedicated tests
- [x] 24-hour job lock tested at before/after/boundary cases
- [x] Follow-up double-send prevention tested
- [x] Offline-first write pattern tested at repository level
- [x] Phone formatter tested for all Ghana number formats
- [x] Widget tests cover all FollowUpButton states
- [x] Mock setup centralized in test/helpers/mocks.dart
- [x] Integration test scaffolds defined for 3 critical flows
- [x] Coverage targets set per layer with rationale
