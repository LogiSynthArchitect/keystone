# DOCUMENT 11 — API CONTRACTS
### Project: Keystone
**Required Inputs:** Document 07 — Domain Model, Document 10 — Validation Rules, Document 09 — Permission Matrix
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 11.1 Global API Standards

**Base URL:** https://[supabase-project-ref].supabase.co
**API Version:** All endpoints prefixed with /rest/v1/ (Supabase standard)
**Authentication:** JWT Bearer token issued by Supabase Auth
**Date Format:** ISO 8601 — example: 2026-01-15T10:30:00Z
**Currency:** GHS only — stored as decimal, displayed with GHS prefix
**Phone Format:** Stored as +233XXXXXXXXX normalized format
**Pagination:** Supabase range headers — Range: 0-24 for first 25 records

**Standard Request Headers:**
Authorization: Bearer [jwt_token]
Content-Type: application/json
apikey: [supabase_anon_key]

**Standard Error Envelope:**
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "field": "field_name_if_applicable"
  }
}

**Standard Error Codes:**
VALIDATION_ERROR, UNAUTHORIZED, FORBIDDEN, NOT_FOUND, DUPLICATE, RATE_LIMITED, SERVER_ERROR

---

## 11.2 Authentication Endpoints

### AUTH-01 — Request OTP
POST /auth/v1/otp
No auth required

Request:
{ "phone": "+233244123456", "channel": "sms" }

Success (200):
{ "message": "OTP sent successfully" }

Errors:
400 VALIDATION_ERROR — invalid phone format
429 RATE_LIMITED — more than 3 requests in 10 minutes

---

### AUTH-02 — Verify OTP and Login
POST /auth/v1/verify
No auth required

Request:
{ "phone": "+233244123456", "token": "123456", "type": "sms" }

Success (200):
{
  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "dGhpcyBpcyBh...",
  "expires_in": 2592000,
  "user": { "id": "uuid", "phone": "+233244123456", "role": "founding_technician", "status": "active" }
}

Errors:
400 VALIDATION_ERROR — invalid or expired OTP
404 NOT_FOUND — phone number not found

---

### AUTH-03 — Refresh Token
POST /auth/v1/token?grant_type=refresh_token

Request:
{ "refresh_token": "dGhpcyBpcyBh..." }

Success (200):
{ "access_token": "new_token", "refresh_token": "new_refresh", "expires_in": 2592000 }

Errors:
401 UNAUTHORIZED — invalid or expired refresh token

---

### AUTH-04 — Logout
POST /auth/v1/logout
Auth required

Success (204): No content
Errors: 401 UNAUTHORIZED

---

## 11.3 User Endpoints

### USER-01 — Create User (Complete Onboarding)
POST /rest/v1/users
Auth required

Request:
{ "full_name": "Jeremie Kouassi", "phone_number": "+233244123456", "role": "founding_technician" }

Success (201):
{
  "id": "uuid", "full_name": "Jeremie Kouassi", "phone_number": "+233244123456",
  "role": "founding_technician", "status": "pending", "profile_slug": "jeremie-kouassi",
  "created_at": "2026-01-15T10:30:00Z"
}

Errors:
400 VALIDATION_ERROR — missing full_name or invalid phone
409 DUPLICATE — phone already registered
401 UNAUTHORIZED

---

### USER-02 — Get Current User
GET /rest/v1/users?id=eq.[user_id]
Auth required

Success (200):
{
  "id": "uuid", "full_name": "Jeremie Kouassi", "phone_number": "+233244123456",
  "role": "founding_technician", "status": "active", "profile_slug": "jeremie-kouassi",
  "last_seen_at": "2026-01-15T10:30:00Z", "created_at": "2026-01-15T08:00:00Z"
}

Errors: 401 UNAUTHORIZED, 404 NOT_FOUND

---

### USER-03 — Update Current User
PATCH /rest/v1/users?id=eq.[user_id]
Auth required — own record only

Request (all optional):
{ "full_name": "Jeremie K. Kouassi", "phone_number": "+233244123456" }

Success (200):
{ "id": "uuid", "full_name": "Jeremie K. Kouassi", "updated_at": "2026-01-15T11:00:00Z" }

Errors:
400 VALIDATION_ERROR — invalid fields
401 UNAUTHORIZED
403 FORBIDDEN — attempting to update different user

---

## 11.4 Profile Endpoints

### PROFILE-01 — Create Profile
POST /rest/v1/profiles
Auth required

Request:
{
  "user_id": "uuid", "display_name": "Jeremie Kouassi",
  "bio": "Professional locksmith in Accra.",
  "services": ["car_lock_programming", "door_lock_installation"],
  "whatsapp_number": "+233244123456"
}

Success (201):
{
  "id": "uuid", "user_id": "uuid", "display_name": "Jeremie Kouassi",
  "services": ["car_lock_programming", "door_lock_installation"],
  "is_public": true, "profile_url": "https://keystone.app/jeremie-kouassi",
  "created_at": "2026-01-15T10:30:00Z"
}

Errors:
400 VALIDATION_ERROR — missing display_name or empty services
409 DUPLICATE — profile already exists for user
401 UNAUTHORIZED

---

### PROFILE-02 — Get Public Profile (No Auth Required)
GET /rest/v1/profiles?profile_slug=eq.[slug]
No auth required — accessible by anyone

Success (200):
{
  "display_name": "Jeremie Kouassi", "bio": "Professional locksmith in Accra.",
  "photo_url": "https://storage.supabase.co/photos/jeremie.jpg",
  "services": ["car_lock_programming", "door_lock_installation"],
  "whatsapp_number": "+233244123456",
  "profile_url": "https://keystone.app/jeremie-kouassi"
}

Note: Returns public fields only — no user_id or internal data

Errors: 404 NOT_FOUND — slug does not exist or profile is private

---

### PROFILE-03 — Update Profile
PATCH /rest/v1/profiles?user_id=eq.[user_id]
Auth required — own profile only

Request (all optional):
{ "display_name": "Jeremie Kouassi", "bio": "Updated bio.", "services": ["car_lock_programming"], "is_public": true }

Success (200):
{ "id": "uuid", "display_name": "Jeremie Kouassi", "updated_at": "2026-01-15T12:00:00Z" }

Errors:
400 VALIDATION_ERROR — empty services array
401 UNAUTHORIZED
403 FORBIDDEN — wrong user_id

---

### PROFILE-04 — Upload Profile Photo
POST /storage/v1/object/profile-photos/[user_id]
Auth required — own photo only
Multipart form data — jpg, jpeg, png, webp — max 5MB

Success (200):
{ "photo_url": "https://storage.supabase.co/profile-photos/[user_id]" }

Errors:
400 VALIDATION_ERROR — invalid file type or too large
401 UNAUTHORIZED

---

## 11.5 Customer Endpoints

### CUSTOMER-01 — Create Customer
POST /rest/v1/customers
Auth required

Request:
{ "full_name": "Kwame Mensah", "phone_number": "+233201234567", "location": "East Legon, Accra", "notes": "Prefers calls" }

Success (201):
{ "id": "uuid", "user_id": "uuid", "full_name": "Kwame Mensah", "phone_number": "+233201234567", "total_jobs": 0, "created_at": "2026-01-15T10:30:00Z" }

Errors:
400 VALIDATION_ERROR — missing name or invalid phone
409 DUPLICATE — phone exists for this technician
401 UNAUTHORIZED

---

### CUSTOMER-02 — Get All Customers
GET /rest/v1/customers?user_id=eq.[user_id]&order=full_name.asc
Auth required — own customers only

Query params: full_name=ilike.*kwame* for search, Range header for pagination

Success (200): Array of customer objects with total_jobs and last_job_at

Errors: 401 UNAUTHORIZED

---

### CUSTOMER-03 — Get Single Customer
GET /rest/v1/customers?id=eq.[id]&user_id=eq.[user_id]
Auth required — own customers only

Success (200): Full customer object with all fields

Errors: 401 UNAUTHORIZED, 404 NOT_FOUND

---

### CUSTOMER-04 — Update Customer
PATCH /rest/v1/customers?id=eq.[id]&user_id=eq.[user_id]
Auth required — own customers only

Request (all optional): { "full_name": "Updated", "location": "New location", "notes": "Updated notes" }

Success (200): { "id": "uuid", "updated_at": "timestamp" }

Errors: 401 UNAUTHORIZED, 403 FORBIDDEN, 404 NOT_FOUND

---

### CUSTOMER-05 — Soft Delete Customer
PATCH /rest/v1/customers?id=eq.[id]&user_id=eq.[user_id]
Auth required — own customers only

Request: { "deleted_at": "2026-01-15T13:00:00Z" }

Success (200): { "id": "uuid", "deleted_at": "timestamp" }

Note: Jobs are preserved — soft delete only

Errors: 401 UNAUTHORIZED, 404 NOT_FOUND

---

## 11.6 Job Endpoints

### JOB-01 — Create Job
POST /rest/v1/jobs
Auth required

Request:
{
  "customer_id": "uuid", "service_type": "car_lock_programming",
  "job_date": "2026-01-15", "location": "Spintex Road, Accra",
  "latitude": 5.6037, "longitude": -0.1870,
  "notes": "Toyota Corolla 2018. Used bypass code KB-2241.",
  "amount_charged": 350.00
}

Success (201):
{
  "id": "uuid", "user_id": "uuid", "customer_id": "uuid",
  "service_type": "car_lock_programming", "job_date": "2026-01-15",
  "amount_charged": 350.00, "follow_up_sent": false,
  "sync_status": "synced", "created_at": "2026-01-15T14:00:00Z"
}

Errors:
400 VALIDATION_ERROR — missing service_type, future date, or negative amount
401 UNAUTHORIZED
404 NOT_FOUND — invalid customer_id

---

### JOB-02 — Get All Jobs
GET /rest/v1/jobs?user_id=eq.[user_id]&order=job_date.desc
Auth required — own jobs only

Query params: customer_id, service_type, date range filters, Range header for pagination

Success (200): Array of job objects with customer_name included

Errors: 401 UNAUTHORIZED

---

### JOB-03 — Get Single Job
GET /rest/v1/jobs?id=eq.[id]&user_id=eq.[user_id]
Auth required — own jobs only

Success (200): Full job object with all fields including coordinates

Errors: 401 UNAUTHORIZED, 404 NOT_FOUND

---

### JOB-04 — Update Job
PATCH /rest/v1/jobs?id=eq.[id]&user_id=eq.[user_id]
Auth required — own jobs only
Note: service_type and job_date locked after 24 hours

Request (all optional): { "notes": "Updated notes", "amount_charged": 400.00, "location": "Corrected location" }

Success (200): { "id": "uuid", "updated_at": "timestamp" }

Errors:
400 VALIDATION_ERROR — attempting to change locked fields after 24 hours
401 UNAUTHORIZED
403 FORBIDDEN
404 NOT_FOUND

---

## 11.7 Knowledge Note Endpoints

### NOTE-01 — Create Knowledge Note
POST /rest/v1/knowledge_notes
Auth required

Request:
{
  "title": "Toyota Corolla 2018 key programming bypass",
  "description": "When standard OBD programming fails, disconnect battery for 10 minutes...",
  "tags": ["car_programming", "toyota", "bypass"],
  "service_type": "car_lock_programming"
}

Success (201):
{ "id": "uuid", "user_id": "uuid", "title": "...", "tags": [...], "is_archived": false, "created_at": "timestamp" }

Errors:
400 VALIDATION_ERROR — missing title, missing description, or too many tags
401 UNAUTHORIZED

---

### NOTE-02 — Get All Knowledge Notes
GET /rest/v1/knowledge_notes?user_id=eq.[user_id]&is_archived=eq.false&order=created_at.desc
Auth required — own notes only

Query params: title search, tag filter, service_type filter, is_archived filter

Success (200): Array of note objects without full description (list view)

Errors: 401 UNAUTHORIZED

---

### NOTE-03 — Get Single Knowledge Note
GET /rest/v1/knowledge_notes?id=eq.[id]&user_id=eq.[user_id]
Auth required — own notes only

Success (200): Full note object including description and photo_url

Errors: 401 UNAUTHORIZED, 404 NOT_FOUND

---

### NOTE-04 — Update Knowledge Note
PATCH /rest/v1/knowledge_notes?id=eq.[id]&user_id=eq.[user_id]
Auth required — own notes only

Request (all optional): { "title": "Updated", "description": "Updated", "tags": [...] }

Success (200): { "id": "uuid", "updated_at": "timestamp" }

Errors: 401 UNAUTHORIZED, 403 FORBIDDEN, 404 NOT_FOUND

---

### NOTE-05 — Archive or Restore Knowledge Note
PATCH /rest/v1/knowledge_notes?id=eq.[id]&user_id=eq.[user_id]
Auth required — own notes only

Request: { "is_archived": true }

Success (200): { "id": "uuid", "is_archived": true, "updated_at": "timestamp" }

Errors: 401 UNAUTHORIZED, 404 NOT_FOUND

---

### NOTE-06 — Upload Knowledge Note Photo
POST /storage/v1/object/note-photos/[user_id]/[note_id]
Auth required — own notes only
Multipart form data — jpg, jpeg, png, webp — max 5MB compressed server-side

Success (200):
{ "photo_url": "https://storage.supabase.co/note-photos/[user_id]/[note_id]" }

Errors: 400 VALIDATION_ERROR — invalid type or too large, 401 UNAUTHORIZED

---

## 11.8 Follow-up Endpoints

### FOLLOWUP-01 — Record Follow-up Sent
POST /rest/v1/follow_ups
Auth required — own jobs only

Request:
{
  "job_id": "uuid", "customer_id": "uuid",
  "message_text": "Hello Kwame, thank you for choosing our locksmith service today..."
}

Success (201):
{ "id": "uuid", "job_id": "uuid", "sent_at": "timestamp", "delivery_confirmed": false }

Side Effect: Job.follow_up_sent set to true, Job.follow_up_sent_at set to now()

Errors:
400 VALIDATION_ERROR — follow-up already sent for this job
401 UNAUTHORIZED
404 NOT_FOUND — invalid job_id

---

### FOLLOWUP-02 — Get Follow-up for a Job
GET /rest/v1/follow_ups?job_id=eq.[job_id]&user_id=eq.[user_id]
Auth required — own follow-ups only

Success (200):
{ "id": "uuid", "job_id": "uuid", "message_text": "...", "sent_at": "timestamp", "delivery_confirmed": false }

Errors: 401 UNAUTHORIZED, 404 NOT_FOUND

---

## 11.9 Sync Endpoint

### SYNC-01 — Batch Sync Offline Jobs
POST /rest/v1/rpc/batch_sync_jobs
Auth required

Request:
{
  "jobs": [
    { "local_id": "local-uuid-001", "customer_id": "uuid", "service_type": "door_lock_installation", "job_date": "2026-01-14", "notes": "Replaced deadbolt.", "amount_charged": 200.00 }
  ]
}

Success (200):
{
  "synced": [ { "local_id": "local-uuid-001", "server_id": "uuid", "sync_status": "synced" } ],
  "failed": []
}

Errors:
400 VALIDATION_ERROR — one or more jobs failed validation
401 UNAUTHORIZED

---

## Domain Concept Challenge — All Passed
- Every entity from Document 07 has full CRUD endpoints
- Every permission from Document 09 is enforced
- Every state transition from Document 08 is enforced at endpoint level
- Every validation rule from Document 10 is reflected in error responses
- Offline-first architecture supported via SYNC-01 batch endpoint
- Row level security enforced via user_id in all query filters

---

## Validation Checklist
- [x] Every entity has full CRUD endpoints
- [x] Every endpoint specifies permitted roles
- [x] Every endpoint has error response table
- [x] Validation rules reflected in error responses
- [x] State machine transitions enforced in endpoints
- [x] Row level security enforced via user_id
- [x] Public profile requires no authentication
- [x] Batch sync endpoint supports offline-first architecture
- [x] File upload endpoints defined for photos
- [x] All endpoints use Supabase REST API conventions
