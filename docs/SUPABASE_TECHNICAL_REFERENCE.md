# Supabase Technical Reference: Keystone Backend

## 1. Schema Overview (Public)

### Table: `users`
The core technician registry.
- **Columns:** `id` (PK), `auth_id` (Link to Auth), `full_name`, `phone_number`, `email`, `role`, `status`, `profile_slug`, `last_seen_at`.
- **Note:** `profile_slug` is managed by a database trigger.

### Table: `profiles`
Public-facing technician profiles.
- **Foreign Key:** `user_id` -> `auth.users.id`
- **Automation:** Updates its own `updated_at` via trigger.

### Table: `customers`
- **Note:** Stores `total_jobs` and `last_job_at`, which are automatically updated when jobs are logged.

### Table: `jobs`
- **Security:** Fields may be "locked" after creation via `trigger_enforce_job_lock`.
- **Relations:** Links to `public.users(id)` and `public.customers(id)`.

---

## 2. Automated Database Logic (Triggers)

| Trigger Name | Action | Logic Description |
| --- | --- | --- |
| `trigger_generate_profile_slug` | INSERT | Automatically creates a URL-friendly slug for new technicians. |
| `trigger_update_customer_stats` | INSERT | Updates customer summary data whenever a job is added. |
| `trigger_update_job_follow_up` | INSERT | Links follow-up records back to job status updates. |
| `trigger_enforce_job_lock` | UPDATE | Prevents modification of finalized job data. |

---

## 3. Data Integrity & Types
The database uses custom domains and enums to enforce strict formatting:
- **`user_role`**: `technician`, `founding_technician`, `admin`.
- **`user_status`**: `pending`, `active`, `suspended`.
- **`sync_status`**: Handles offline-first logic transitions.
- **`service_type`**: Shared across jobs and profiles.

---

## 4. RLS & Security Model
Access is governed by `auth.uid()`. 
- **Pattern A (Direct):** Tables like `customers` check `auth.uid() == user_id`.
- **Pattern B (Relational):** Tables like `jobs` check the `auth_id` inside the `users` table to verify ownership.
