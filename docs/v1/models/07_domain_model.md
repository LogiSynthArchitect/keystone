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
 └── has many FollowUps

Customer
 ├── belongs to User
 └── has many Jobs

Job
 ├── belongs to User
 ├── belongs to Customer
 └── has one FollowUp

KnowledgeNote
 └── belongs to User

Profile
 └── belongs to User

FollowUp
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
| full_name | String | Yes | No | none | Technician full name |
| phone_number | String | Yes | Yes | none | WhatsApp number — used for deep links |
| email | String | No | Yes | null | Optional — for future auth methods |
| password_hash | String | Yes | No | none | Hashed password for authentication |
| role | Enum | Yes | No | technician | Values: technician, founding_technician, admin |
| status | Enum | Yes | No | active | Values: active, suspended, pending |
| profile_slug | String | Yes | Yes | auto | URL-friendly unique identifier for public profile |
| created_at | Timestamp | Yes | No | now() | Account creation time |
| updated_at | Timestamp | Yes | No | now() | Last update time |
| last_seen_at | Timestamp | No | No | null | Last time user opened the app |

**Relationships:**
- Has one: Profile
- Has many: Customers
- Has many: Jobs
- Has many: KnowledgeNotes
- Has many: FollowUps

**Business Rules:**
- Phone number must be a valid Ghana or international format
- profile_slug is auto-generated from full_name and must be unique across all users
- role of founding_technician is assigned manually — cannot be self-assigned
- A suspended user cannot log jobs, send follow-ups, or access their profile link

---

## Entity 2 — Profile

**Description:** The public-facing page for a technician. Accessible via a shareable
link without any app download. Represents the technician's professional identity.
**Owned By:** User — created automatically when User is created

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| user_id | UUID | Yes | Yes | none | Foreign key — belongs to one User |
| display_name | String | Yes | No | none | Name shown on public profile |
| bio | String | No | No | null | Short description of the technician |
| photo_url | String | No | No | null | URL to profile photo in cloud storage |
| services | Array | Yes | No | [] | List of service types offered |
| whatsapp_number | String | Yes | No | none | Number shown on public profile for contact |
| is_public | Boolean | Yes | No | true | Whether the profile link is active |
| profile_url | String | Yes | Yes | auto | Full public URL — generated from user profile_slug |
| created_at | Timestamp | Yes | No | now() | Profile creation time |
| updated_at | Timestamp | Yes | No | now() | Last update time |

**Relationships:**
- Belongs to: User (one to one)

**Business Rules:**
- profile_url format: keystone.app/[profile_slug]
- services array must contain at least one service type
- If is_public is false the profile URL returns a 404
- photo_url must point to a valid cloud storage URL if provided
- Profile is created automatically when User completes onboarding

**Service Type Enum Values (V1):**
- car_lock_programming
- door_lock_installation
- door_lock_repair
- smart_lock_installation

---

## Entity 3 — Customer

**Description:** A person or business that has received service from a technician.
Customers are private to the technician who created them in V1.
**Owned By:** User — created when a job is logged for a new customer

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| user_id | UUID | Yes | No | none | Foreign key — belongs to one User |
| full_name | String | Yes | No | none | Customer name as entered by technician |
| phone_number | String | Yes | No | none | Customer WhatsApp or call number |
| location | String | No | No | null | General area or address — free text |
| notes | String | No | No | null | General notes about this customer (not job-specific) |
| total_jobs | Integer | Yes | No | 0 | Count of all jobs logged for this customer |
| last_job_at | Timestamp | No | No | null | Date of most recent job |
| created_at | Timestamp | Yes | No | now() | When customer was first added |
| updated_at | Timestamp | Yes | No | now() | Last update time |

**Relationships:**
- Belongs to: User
- Has many: Jobs

**Business Rules:**
- Phone number uniqueness is scoped per user — same customer phone can exist
  under different technicians but not twice under the same technician
- total_jobs is updated automatically every time a new job is logged for this customer
- last_job_at is updated automatically every time a new job is logged
- Deleting a customer does not delete their jobs — jobs are preserved with a
  reference to the deleted customer record (soft relationship)
- Customer notes are general notes about the person — not about a specific job
  Job-specific notes live on the Job entity

---

## Entity 4 — Job

**Description:** A single completed job logged by a technician. This is the central
entity of the entire system — everything else connects to or supports this entity.
**Owned By:** User — created when technician logs a completed job

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| user_id | UUID | Yes | No | none | Foreign key — belongs to one User |
| customer_id | UUID | Yes | No | none | Foreign key — belongs to one Customer |
| service_type | Enum | Yes | No | none | Type of service performed |
| job_date | Date | Yes | No | today | Date the job was completed |
| location | String | No | No | null | Job site address or area — free text |
| latitude | Float | No | No | null | GPS latitude if map pin used |
| longitude | Float | No | No | null | GPS longitude if map pin used |
| notes | String | No | No | null | Technical or general notes about this specific job |
| amount_charged | Decimal | No | No | null | Amount charged in GHS — optional |
| follow_up_sent | Boolean | Yes | No | false | Whether WhatsApp follow-up was sent |
| follow_up_sent_at | Timestamp | No | No | null | When follow-up was sent |
| sync_status | Enum | Yes | No | pending | Values: pending, synced, failed |
| created_at | Timestamp | Yes | No | now() | When job was logged |
| updated_at | Timestamp | Yes | No | now() | Last update time |

**Relationships:**
- Belongs to: User
- Belongs to: Customer
- Has one: FollowUp

**Business Rules:**
- service_type must be one of the defined enum values
- job_date defaults to today but can be set to a past date — never a future date
- amount_charged must be positive if provided — zero or negative values not allowed
- sync_status starts as pending, moves to synced when cloud confirms, failed if sync errors
- follow_up_sent is updated to true when technician sends WhatsApp message
- A job cannot be deleted — it can only be archived to preserve customer history integrity
- Job notes are about this specific job — customer general notes live on the Customer entity

**Service Type Enum Values:**
- car_lock_programming
- door_lock_installation
- door_lock_repair
- smart_lock_installation

---

## Entity 5 — KnowledgeNote

**Description:** A technical solution, bypass code, tip, or insight saved by a technician
after a difficult or unusual job. Private to the technician who created it in V1.
**Owned By:** User — created when technician saves a technical note

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| user_id | UUID | Yes | No | none | Foreign key — belongs to one User |
| title | String | Yes | No | none | Short descriptive title of the note |
| description | String | Yes | No | none | Full technical detail — no character limit |
| tags | Array | No | No | [] | List of searchable tags |
| photo_url | String | No | No | null | URL to optional photo in cloud storage |
| service_type | Enum | No | No | null | Related service type — for filtering |
| is_archived | Boolean | Yes | No | false | Archived notes hidden from main list |
| created_at | Timestamp | Yes | No | now() | When note was created |
| updated_at | Timestamp | Yes | No | now() | Last update time |

**Relationships:**
- Belongs to: User

**Business Rules:**
- title is required — description is required — everything else is optional
- tags array can be empty but if provided each tag must be a non-empty string
- photo_url must point to a valid cloud storage URL if provided
- Archived notes are not deleted — they are hidden from the main list
- service_type is optional but enables filtering by service category
- Notes are private to each technician — no sharing in V1

**Suggested Default Tags:**
bypass, programming, door_lock, smart_lock, car_key, tip, warning, tool_required

---

## Entity 6 — FollowUp

**Description:** A record of a WhatsApp follow-up message sent to a customer after a job.
**Owned By:** User — created when technician sends a WhatsApp follow-up

| Field Name | Data Type | Required | Unique | Default | Description |
|---|---|---|---|---|---|
| id | UUID | Yes | Yes | auto | Primary key |
| job_id | UUID | Yes | Yes | none | Foreign key — belongs to one Job |
| user_id | UUID | Yes | No | none | Foreign key — belongs to one User |
| customer_id | UUID | Yes | No | none | Foreign key — belongs to one Customer |
| message_text | String | Yes | No | none | The exact message that was sent |
| sent_at | Timestamp | Yes | No | now() | When follow-up was triggered in Keystone |
| delivery_confirmed | Boolean | Yes | No | false | V1 always false — deep links cannot confirm delivery |
| created_at | Timestamp | Yes | No | now() | Record creation time |

**Relationships:**
- Belongs to: Job (one to one in V1)
- Belongs to: User
- Belongs to: Customer

**Business Rules:**
- One follow-up per job in V1
- delivery_confirmed is always false in V1 — WhatsApp deep links cannot confirm delivery
- delivery_confirmed will be functional in V2 when WhatsApp Business API is integrated
- message_text stores the actual message sent — not just a template reference
- FollowUp record is created when technician taps Send via WhatsApp in Keystone

---

## Entity Relationship Summary

User (1) ──────────────── (1) Profile
User (1) ──────────────── (N) Customer
User (1) ──────────────── (N) Job
User (1) ──────────────── (N) KnowledgeNote
User (1) ──────────────── (N) FollowUp
Customer (1) ───────────── (N) Job
Job (1) ────────────────── (1) FollowUp

---

## Architecture Note — Multi-tenancy Readiness

All entities include user_id as a foreign key. This means:
- Every piece of data is scoped to a specific technician
- In V2/V3 when multiple technicians join, their data is automatically isolated
- No data migration needed when expanding from 2 users to 200 users
- The foundation is multi-tenant from day one

Flutter Clean Architecture alignment:
- Domain layer: Pure Dart entity classes — no Flutter dependencies
- Data layer: Repository implementations with local DB (Hive or Isar) and remote sync
- Presentation layer: UI only — reads from domain, never touches data directly

UI Note for Document 15 and 16:
- Customer.notes and Job.notes are two different fields serving two different purposes
- Customer notes = general notes about the person
- Job notes = specific notes about one job
- These must be visually distinguished in the UI to prevent technician confusion

---

## Validation Checklist
- [x] Every entity is traceable to a feature in Document 04
- [x] Every entity has id, created_at, and updated_at
- [x] All relationships are defined and bidirectional
- [x] Business rules are documented per entity
- [x] Enum values are explicitly listed
- [x] Multi-tenancy supported via user_id on all entities
- [x] V1 limitations documented honestly
- [x] Architecture alignment with Flutter Clean Architecture noted
- [x] Customer.notes vs Job.notes distinction flagged for UI documents
