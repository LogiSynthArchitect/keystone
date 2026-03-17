# DOCUMENT 07 — DOMAIN MODEL
### Project: Keystone
**Required Inputs:** Document 04 — Core Scope Definition, Document 06 — Core User Flow
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## Overview — All Entities

User
 ├── has one Profile
 ├── has many Customers
 ├── has many Jobs
 ├── has many KnowledgeNotes
 ├── has many FollowUps
 └── has many CorrectionRequests

Customer
 ├── belongs to User
 └── has many Jobs

Job
 ├── belongs to User
 ├── belongs to Customer
 ├── has one FollowUp
 └── has many CorrectionRequests

KnowledgeNote
 └── belongs to User

Profile
 └── belongs to User

FollowUp
 ├── belongs to Job
 └── belongs to User

CorrectionRequest
 ├── belongs to Job
 └── belongs to User

---

## Entity 1 — User

**Description:** A technician who uses the Keystone app. In V1 this is Jeremie or Jean.
In V2/V3 this expands to other technicians joining the platform.
**Owned By:** Self — created during onboarding

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| auth_id | UUID | Yes | Yes | none | Supabase Auth UID |
| full_name | String | Yes | No | none | Technician full name |
| phone_number | String | Yes | Yes | none | WhatsApp number — used for deep links |
| role | Enum | Yes | No | technician | Values: technician, founding_technician, admin |
| status | Enum | Yes | No | active | Values: active, suspended, pending |
| profile_slug | String | Yes | Yes | auto | URL-friendly unique identifier for public profile |
| created_at | Timestamp | Yes | No | now() | Account creation time |
| updated_at | Timestamp | Yes | No | now() | Last update time |

**Relationships:**
- Has one: Profile
- Has many: Customers
- Has many: Jobs
- Has many: KnowledgeNotes
- Has many: FollowUps
- Has many: CorrectionRequests

---

## Entity 2 — Profile

**Description:** The public-facing page for a technician. Represents the technician's professional identity.
**Owned By:** User — created automatically when User is created

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| user_id | UUID | Yes | Yes | none | Foreign key — belongs to one User |
| display_name | String | Yes | No | none | Name shown on public profile |
| bio | String | No | No | null | Short description of the technician |
| photo_url | String | No | No | null | URL to profile photo |
| services | Array | Yes | No | [] | List of service types offered |
| whatsapp_number | String | Yes | No | none | Contact number shown publicly |
| is_public | Boolean | Yes | No | true | Whether the profile link is active |
| profile_url | String | Yes | Yes | auto | Full public URL |
| created_at | Timestamp | Yes | No | now() | Profile creation time |
| updated_at | Timestamp | Yes | No | now() | Last update time |

---

## Entity 3 — Customer

**Description:** A person or business that has received service from a technician.
**Owned By:** User

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| user_id | UUID | Yes | No | none | Foreign key — belongs to one User |
| full_name | String | Yes | No | none | Customer name |
| phone_number | String | Yes | No | none | Customer contact number |
| location | String | No | No | null | General area or address |
| notes | String | No | No | null | General notes |
| total_jobs | Integer | Yes | No | 0 | Count of all jobs |
| last_job_at | Timestamp | No | No | null | Date of most recent job |
| created_at | Timestamp | Yes | No | now() | Record creation time |
| updated_at | Timestamp | Yes | No | now() | Last update time |

---

## Entity 4 — Job

**Description:** A single completed job logged by a technician.
**Owned By:** User

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| user_id | UUID | Yes | No | none | Foreign key — belongs to one User |
| customer_id | UUID | Yes | No | none | Foreign key — belongs to one Customer |
| service_type | Enum | Yes | No | none | Type of service performed |
| job_date | Date | Yes | No | today | Date job was completed |
| location | String | No | No | null | Site address or area |
| notes | String | No | No | null | Technical or general notes |
| amount_charged | Decimal | No | No | null | Amount in GHS |
| follow_up_sent | Boolean | Yes | No | false | Whether follow-up was triggered |
| sync_status | Enum | Yes | No | pending | Values: pending, synced, failed |
| created_at | Timestamp | Yes | No | now() | When job was logged |
| updated_at | Timestamp | Yes | No | now() | Last update time |

---

## Entity 5 — KnowledgeNote

**Description:** Technical solutions, tips, or insights saved by a technician.
**Owned By:** User

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| user_id | UUID | Yes | No | none | Foreign key — belongs to one User |
| title | String | Yes | No | none | Descriptive title |
| description | String | Yes | No | none | Full technical detail |
| tags | Array | No | No | [] | Searchable tags |
| service_type | Enum | No | No | null | Related category |
| is_archived | Boolean | Yes | No | false | Hidden from main list |
| created_at | Timestamp | Yes | No | now() | Creation time |
| updated_at | Timestamp | Yes | No | now() | Last update time |

---

## Entity 6 — FollowUp

**Description:** A record of a WhatsApp follow-up message sent to a customer.
**Owned By:** User

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| job_id | UUID | Yes | Yes | none | Foreign key — belongs to one Job |
| user_id | UUID | Yes | No | none | Foreign key — belongs to one User |
| customer_id | UUID | Yes | No | none | Foreign key — belongs to one Customer |
| message_text | String | Yes | No | none | The exact message sent |
| sent_at | Timestamp | Yes | No | now() | When triggered in app |
| created_at | Timestamp | Yes | No | now() | Record creation time |

---

## Entity 7 — CorrectionRequest

**Description:** A request to change locked job data (Service Type/Date) after the 24h lock.
**Owned By:** User

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| job_id | UUID | Yes | No | none | Foreign key — the target job |
| user_id | UUID | Yes | No | none | Foreign key — the requesting tech |
| reason | String | Yes | No | none | Explanation for change |
| status | Enum | Yes | No | pending | Values: pending, approved, rejected |
| admin_notes | String | No | No | null | Feedback from admin |
| created_at | Timestamp | Yes | No | now() | Creation time |
| updated_at | Timestamp | Yes | No | now() | Last update time |

**Business Rules:**
- Only one 'pending' request permitted per job.
- Approved requests trigger an automatic update to the target job record.

---

## Entity Relationship Summary

User (1) ──────────────── (1) Profile
User (1) ──────────────── (N) Customer
User (1) ──────────────── (N) Job
User (1) ──────────────── (N) KnowledgeNote
User (1) ──────────────── (N) FollowUp
User (1) ──────────────── (N) CorrectionRequest
Customer (1) ───────────── (N) Job
Job (1) ────────────────── (1) FollowUp
Job (1) ────────────────── (N) CorrectionRequest

---

## Architecture Note

All entities include `user_id` for multi-tenancy isolation. 
The system uses an **Offline-First Repository Pattern** where local Hive storage is the source of truth for the UI, and background synchronization reconciles with Supabase.
