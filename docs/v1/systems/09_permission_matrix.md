# DOCUMENT 09 — PERMISSION MATRIX
### Project: Keystone
**Required Inputs:** Document 05 — User Personas, Document 07 — Domain Model
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 9.1 Roles Defined

| Role | Description | Scope | Who |
|---|---|---|---|
| admin | Full system access — developer only | Everything | You |
| founding_technician | Platform validators with elevated access | Own data + platform oversight | Jeremie and Jean |
| technician | Standard platform member | Own data only | Future technicians V2/V3 |

**Important V1 Note:**
In V1 only admin and founding_technician roles exist in practice.
The technician role is defined now so the permission system supports V2/V3
without any architectural changes.

---

## 9.2 Permission Matrix

### Entity: User

| Action | Admin | Founding Technician | Technician | Notes |
|---|---|---|---|---|
| Create own account | Yes | Yes | Yes | During onboarding only |
| Read own profile | Yes | Yes | Yes | |
| Read any profile | Yes | Yes | No | Founding technician can see all users for platform oversight |
| Update own account | Yes | Yes | Yes | Name, phone, photo only |
| Update any account | Yes | No | No | Admin only |
| Delete own account | Yes | Yes | Yes | Soft delete — data preserved |
| Delete any account | Yes | No | No | Admin only |
| Change own role | No | No | No | Nobody can change their own role |
| Change any role | Yes | No | No | Admin only — database action |
| Suspend any user | Yes | Yes | No | Founding technician can suspend standard technicians only |
| Reactivate any user | Yes | Yes | No | Founding technician can reactivate standard technicians only |

---

### Entity: Profile

| Action | Admin | Founding Technician | Technician | Notes |
|---|---|---|---|---|
| Create own profile | Yes | Yes | Yes | Auto-created on onboarding |
| Read own profile | Yes | Yes | Yes | |
| Read any profile (private app view) | Yes | Yes | No | |
| Read any profile (public URL) | Yes | Yes | Yes | Public URL accessible by anyone including non-users |
| Update own profile | Yes | Yes | Yes | Name, bio, photo, services |
| Update any profile | Yes | No | No | Admin only |
| Toggle own profile public/private | Yes | Yes | Yes | Technician can hide their own profile |
| Toggle any profile public/private | Yes | No | No | Admin only |
| Delete own profile | No | No | No | Profiles are never deleted — only deactivated |
| Delete any profile | Yes | No | No | Admin only — extreme cases |

---

### Entity: Customer

| Action | Admin | Founding Technician | Technician | Notes |
|---|---|---|---|---|
| Create customer | Yes | Yes | Yes | Auto-created when first job is logged |
| Read own customers | Yes | Yes | Yes | Scoped to user_id |
| Read any customer | Yes | No | No | Customers are private per technician |
| Update own customer | Yes | Yes | Yes | Name, phone, location, notes |
| Update any customer | Yes | No | No | Admin only |
| Delete own customer | Yes | Yes | Yes | Soft delete — jobs preserved |
| Delete any customer | Yes | No | No | Admin only |
| Export own customers | Yes | Yes | Yes | V2 feature — documented now for architecture |

---

### Entity: Job

| Action | Admin | Founding Technician | Technician | Notes |
|---|---|---|---|---|
| Create job | Yes | Yes | Yes | Technician logs their own jobs only |
| Read own jobs | Yes | Yes | Yes | Scoped to user_id |
| Read any job | Yes | No | No | Jobs are private per technician |
| Update own job | Yes | Yes | Yes | Notes, amount, location only — service type and date locked after 24 hours |
| Update any job | Yes | No | No | Admin only |
| Archive own job | Yes | Yes | Yes | Jobs cannot be hard deleted |
| Hard delete any job | Yes | No | No | Admin only — extreme cases |
| Trigger follow-up on own job | Yes | Yes | Yes | |
| Trigger follow-up on any job | Yes | No | No | Admin only |

---

### Entity: KnowledgeNote

| Action | Admin | Founding Technician | Technician | Notes |
|---|---|---|---|---|
| Create note | Yes | Yes | Yes | Private to creator |
| Read own notes | Yes | Yes | Yes | |
| Read any note | Yes | No | No | Notes are private per technician in V1 |
| Update own note | Yes | Yes | Yes | Title, description, tags, photo |
| Update any note | Yes | No | No | Admin only |
| Archive own note | Yes | Yes | Yes | |
| Restore own archived note | Yes | Yes | Yes | |
| Hard delete any note | Yes | No | No | Admin only — notes never hard deleted in normal flow |

**V2 Note:**
In V2 founding_technicians may share selected knowledge notes with other technicians.
This will require a new shared_notes permission tier.
Documented here to prevent V1 architecture from blocking it.

---

### Entity: FollowUp

| Action | Admin | Founding Technician | Technician | Notes |
|---|---|---|---|---|
| Create follow-up | Yes | Yes | Yes | Created when Send via WhatsApp is tapped |
| Read own follow-ups | Yes | Yes | Yes | |
| Read any follow-up | Yes | No | No | |
| Update own follow-up | No | No | No | Follow-ups are immutable once created |
| Update any follow-up | Yes | No | No | Admin only — correction purposes |
| Delete own follow-up | No | No | No | Follow-up records are never deleted |
| Delete any follow-up | Yes | No | No | Admin only — extreme cases |

---

## 9.3 Special Permissions

**Row-Level Security — All Entities**
Every query for Customer, Job, KnowledgeNote, and FollowUp data is automatically
filtered by user_id. A technician can never access another technician's data
even if they know the record ID. Enforced at the data layer not just the UI.

**Founding Technician Elevation Rules**
Founding technicians can see the list of all users on the platform but cannot
see another technician's customers, jobs, knowledge notes, or follow-ups.
Their oversight is limited to user account management — not data access.

**Time-Based Permission — Job Updates**
A technician can edit service_type and job_date only within 24 hours of creating
the job. After 24 hours these fields are locked to prevent historical data
manipulation. Notes, amount, and location remain editable indefinitely.

**Profile Public Access**
The public profile URL is accessible by anyone — no authentication required.
Contains only public information: name, photo, services, and WhatsApp contact button.

**Admin Access**
Admin access is never exposed through the app UI.
All admin actions performed directly in the database or through a separate
admin interface built in V3. In V1 and V2 the developer performs admin actions directly.

---

## 9.4 Authentication Rules

- All app routes except the public profile URL require authentication
- Authentication uses JWT tokens with 30-day expiry
- Refresh tokens valid for 90 days
- On token expiry user is redirected to login — data cached locally remains accessible
- Failed login attempts: lock account after 5 consecutive failures for 15 minutes

**OTP Delivery:**
- V1: SMS OTP via Africa's Talking
  - Supports MTN Ghana, Vodafone Ghana, and AirtelTigo directly
  - Ghanaian users already familiar with SMS OTP from MTN Mobile Money
  - Cost: approximately $0.02-$0.04 USD per SMS
  - No third-party app approval required — works immediately
- V2: WhatsApp OTP via WhatsApp Business API
  - Switch when API is already integrated for follow-up messages
  - Covered under existing conversation fees — no extra cost
  - More natural for urban Ghanaian users

**Why Africa's Talking over Twilio:**
- Local African infrastructure — better delivery rates in Ghana
- Supports all three major Ghanaian networks directly
- Used by many Ghanaian apps and services
- Cheaper rates for African SMS than global providers like Twilio

---

## Validation Checklist
- [x] All three roles defined with clear scope
- [x] Every entity has a complete permission table
- [x] Row-level security documented — user_id scoping on all entities
- [x] Special permissions and exceptions documented
- [x] Time-based permissions documented for Job updates
- [x] Public profile access rules documented
- [x] V1 limitations and V2 expansions noted where relevant
- [x] Authentication rules defined
- [x] OTP delivery method confirmed — Africa's Talking SMS in V1
