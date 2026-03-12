# Keystone Supabase Architecture Documentation

## 1. Identity Architecture
The system follows a linked identity model.

| Entity | Schema | Key ID Type | Purpose |
| --- | --- | --- | --- |
| **Auth User** | `auth` | `UID` (Supabase) | Login, Session, Security JWT |
| **App User** | `public.users` | `UUID` (Table PK) | Profile status, Role (Founding/Admin), Phone |
| **Profile** | `public.profiles` | `UUID` (Auth UID) | Public-facing technician identity |

---

## 2. Table Definitions & Relationships

### `public.users` (The Central Hub)
- **Primary Key:** `id` (UUID)
- **Link:** `auth_id` -> `auth.users.id`
- **Logic:** Every technician MUST have a record here to see their own data.
- **Notable Columns:** `role` (technician/founding_technician), `status` (pending/active).

### `public.profiles`
- **Primary Key:** `id` (UUID)
- **Foreign Key:** `user_id` -> **`auth.users.id`** (Confirmed via Audit)
- **Logic:** This table stores public info (bio, services). It uses the Auth UID directly.

### `public.jobs`
- **Primary Key:** `id` (UUID)
- **Foreign Key:** `user_id` -> `public.users.id`
- **Foreign Key:** `customer_id` -> `public.customers.id`

### `public.customers`
- **Primary Key:** `id` (UUID)
- **Owner:** `user_id` -> `public.users.id`
- **Note:** Contains `USER-DEFINED` type for `phone_number`.

---

## 3. Security (Row Level Security)

All tables have RLS **ENABLED**.

### Security Patterns:
1. **Direct Ownership:** `auth.uid() = user_id`
   - Used by: `app_events`, `customers`, `knowledge_notes`.
2. **Nested Ownership:** `user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())`
   - Used by: `jobs`, `profiles`, `follow_ups`.
   - **CRITICAL:** This means if a user record is missing from the `users` table, the technician will see 0 jobs, even if they are logged in.

---

## 4. Custom Database Types
The schema utilizes PostgreSQL Enums for strict data integrity:
- `user_role`: `technician`, `founding_technician`, `admin`
- `user_status`: `pending`, `active`, `suspended`
- `service_type`: Used in `profiles` and `jobs`.
- `sync_status`: `pending`, `synced`.

## 5. Maintenance Notes
- **Deletion:** Deleting a `customer` uses "Soft Delete" logic (`deleted_at IS NULL` check in RLS).
- **Versioning:** All tables include `created_at` and `updated_at` timestamps managed by `now()`.
