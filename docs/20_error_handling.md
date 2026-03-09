# DOCUMENT 20 — ERROR HANDLING STRATEGY
### Project: Keystone
**Required Inputs:** Document 10 — Validation Rules, Document 13 — Flutter Architecture, Document 19 — Integrations
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 20.1 Philosophy

1. Never lose data — if something fails, data stays on device
2. Never block the user — errors are non-blocking where possible
3. Speak plainly — no error codes, no stack traces in UI

---

## 20.2 Error Class Hierarchy

abstract class AppException implements Exception:
  final String message   — user-facing plain English
  final String code      — internal code for logging
  final String? field    — field name if validation error
  final Object? cause    — original exception for logging

class NetworkException  extends AppException
class StorageException  extends AppException
class ValidationException extends AppException
class AuthException     extends AppException

---

## 20.3 Error Flow

Database/Supabase → throws PostgrestException / AuthException
Data datasources  → catches, wraps into NetworkException or StorageException
Data repositories → offline writes return success (saved locally, no error thrown)
Domain use cases  → validation → throws ValidationException before any I/O
                  → re-throws AppException from repository
Presentation      → AsyncValue.guard() catches all AppException → AsyncError
Widgets           → state.hasError → KsSnackbar or inline field error

---

## 20.4 Data Layer Pattern

JobRemoteDatasource.createJob():
  try → supabase insert → return JobModel
  on PostgrestException → throw NetworkException(message: 'Could not save your job.', code: 'JOB_CREATE_FAILED', cause: e)
  on SocketException   → throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION')
  catch (e)            → throw NetworkException(message: 'Something went wrong.', code: 'UNKNOWN', cause: e)

---

## 20.5 Repository Layer — Offline-First Guarantee

JobRepositoryImpl.createJob():
  Step 1: localDatasource.saveJob() — MUST succeed
    on StorageException → throw StorageException(LOCAL_SAVE_FAILED) — only blocking error

  Step 2: if online → remoteDatasource.createJob()
    on NetworkException → updateSyncStatus(pending) — non-fatal, data safe locally
    on success         → updateSyncStatus(synced, serverId)

  Returns local data in both cases — user always sees their job

---

## 20.6 Use Case Validation Pattern

LogJobUsecase.call():
  if serviceType == null     → throw ValidationException(SERVICE_TYPE_REQUIRED, field: service_type)
  if jobDate.isAfter(now)    → throw ValidationException(JOB_DATE_FUTURE, field: job_date)
  if amountCharged < 0       → throw ValidationException(AMOUNT_NEGATIVE, field: amount_charged)
  → _repository.createJob(params)

Validation always runs before I/O. No network call if invalid.

---

## 20.7 Presentation Pattern

Provider: state = await AsyncValue.guard(() => _usecase(params))

Widget listener:
  data → showKsSnackbar(success) + context.pop()
  error (ValidationException with field) → setState fieldErrors[field] = message
  error (other AppException) → showKsSnackbar(error, error.message)
  error (unknown) → showKsSnackbar(error, 'Something went wrong. Please try again.')

---

## 20.8 Auth Error Messages

OTP_INVALID:       "Invalid or expired code. Please try again."
OTP_EXPIRED:       "This code has expired. Request a new one."
OTP_RATE_LIMITED:  "Too many attempts. Please wait a moment."
PHONE_NOT_FOUND:   "Phone number not registered."
SESSION_EXPIRED:   "Your session has expired. Please log in again."
AUTH_UNKNOWN:      "Could not sign in. Please try again."

---

## 20.9 Validation Error Messages

SERVICE_TYPE_REQUIRED:   "Please select a service type."              field: service_type
JOB_DATE_FUTURE:         "Job date cannot be in the future."          field: job_date
JOB_DATE_REQUIRED:       "Please enter the job date."                 field: job_date
AMOUNT_NEGATIVE:         "Amount cannot be negative."                 field: amount_charged
AMOUNT_TOO_LARGE:        "Amount seems too high. Please check."       field: amount_charged
CUSTOMER_NAME_REQUIRED:  "Please enter the customer name."            field: full_name
CUSTOMER_NAME_TOO_SHORT: "Name must be at least 2 characters."        field: full_name
PHONE_INVALID:           "Please enter a valid Ghana phone number."   field: phone_number
PHONE_DUPLICATE:         "This customer is already in your list."     field: phone_number
NOTE_TITLE_REQUIRED:     "Please enter a title for this note."        field: title
NOTE_TITLE_TOO_SHORT:    "Title must be at least 3 characters."       field: title
NOTE_DESCRIPTION_REQUIRED: "Please add a description to this note."  field: description
NOTE_TAGS_MAX:           "Maximum 10 tags per note."                  field: tags
DISPLAY_NAME_REQUIRED:   "Please enter your display name."           field: display_name
SERVICE_LIST_EMPTY:      "Please select at least one service."        field: services
FOLLOWUP_ALREADY_SENT:   "You already sent a follow-up for this job." field: —
JOB_FIELD_LOCKED:        "Service type and date cannot be changed after 24 hours." field: varies

---

## 20.10 Network Error Messages

NO_CONNECTION:          "No internet connection. Your changes are saved on your device."  → auto-sync
JOB_CREATE_FAILED:      "Could not save your job to the server. It is saved on your device." → auto-sync
JOB_SYNC_FAILED:        "Some jobs could not sync. They will retry automatically."        → auto-retry
CUSTOMER_LOAD_FAILED:   "Could not load customers. Pull down to try again."               → pull-to-refresh
NOTES_LOAD_FAILED:      "Could not load notes. Pull down to try again."                   → pull-to-refresh
PROFILE_UPDATE_FAILED:  "Could not update your profile. Please try again."                → retry
PHOTO_UPLOAD_FAILED:    "Could not upload photo. Please check your connection."           → retry
PHOTO_TOO_LARGE:        "Photo is too large. Please choose a smaller image."              → user action
PHOTO_INVALID_TYPE:     "Invalid file type. Please use a JPG or PNG."                    → user action

---

## 20.11 Storage Error Messages

LOCAL_SAVE_FAILED: "Could not save to your device. Please check your storage space." → user action
LOCAL_READ_FAILED: "Could not load your data. Please restart the app."               → restart

---

## 20.12 Offline UX

When offline:
1. KsOfflineBanner shown — "You are offline. Changes will sync when reconnected."
2. All writes succeed locally and silently
3. SyncStatusIndicator shows "Saving..." on pending job cards
4. On reconnect — automatic silent sync
5. On sync_status = synced — SyncStatusIndicator disappears
6. After 3 failed retries — non-blocking snackbar:
   "Some jobs could not sync. Your data is safe on your device."
   with "Retry" action → retryFailed()

User never sees a blocking error for being offline. They always see their data.

---

## 20.13 Crash Boundary — app.dart

FlutterError.onError = (details) { log to monitoring; FlutterError.presentError(details); }
PlatformDispatcher.instance.onError = (error, stack) { log to monitoring; return true; }

return true prevents app crash for async unhandled errors.

---

## Validation Checklist
- [x] Error class hierarchy with typed subclasses
- [x] Error flow documented for all 4 layers
- [x] Repository guarantees data safety on network failure
- [x] Complete error message reference — all codes covered
- [x] Auth, validation, network, storage errors all specified
- [x] Offline UX — no blocking errors for connectivity issues
- [x] Sync failure recovery with retry action
- [x] Top-level crash boundary in app.dart
- [x] All messages plain English — no codes or jargon shown
- [x] Field errors inline, general errors as snackbar
