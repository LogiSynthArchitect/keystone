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
| admin | Full system access | Everything | Developer / System Owner |
| founding_technician | Pilot validators | Own data + V1 feedback | Jeremie and Jean |
| technician | Standard member | Own data only | Future Users (V2) |

---

## 9.2 Permission Matrix (Core Actions)

### Entity: Job

| Action | Admin | Founding Technician | Technician | Notes |
|---|---|---|---|---|
| Create Job | Yes | Yes | Yes | Own data only |
| Read Own Jobs | Yes | Yes | Yes | |
| Read Any Job | Yes | No | No | Admin can review for corrections |
| Update Own Job | Yes | Yes | Yes | Limited to notes/amount after 24h |
| Update Any Job | Yes | No | No | Admin can bypass 24h lock via approval |
| Request Correction | No | Yes | Yes | For locked job data |

### Entity: CorrectionRequest

| Action | Admin | Founding Technician | Technician | Notes |
|---|---|---|---|---|
| Create Request | No | Yes | Yes | One pending request per job |
| Read Own Requests | No | Yes | Yes | |
| Read All Pending | Yes | No | No | In Admin Dashboard |
| Approve/Reject | Yes | No | No | Triggers Job Update on Approve |

---

## 9.3 Special Rules

**Job Integrity Lock (24h)**
Technicians are restricted from editing `service_type` and `job_date` 24 hours after a job is synced. This ensures financial auditability.

**Admin Override Path**
Admins have overarching write permissions on `jobs` and `customers` specifically to resolve technician errors via the in-app **Admin Dashboard**.

**Row-Level Security (RLS)**
Enforced at the database level. Technicians are isolated by `user_id`. Admins bypass this isolation via specialized `admin_all` policies.
