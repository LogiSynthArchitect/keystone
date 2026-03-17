# ADMIN RUNBOOK: MANUAL OVERRIDES
### Project: Keystone
### Purpose: Procedures for administrative database interventions during the V1 Pilot

---

## 1. The 24-Hour Job Lock Bypass
Technicians are locked from editing `service_type` and `job_date` 24 hours after a job is synced. If a genuine error was made, follow this procedure.

### Step 1: Verify the Request
- Ensure the request came from a verified technician.
- Note the `job_id` and the reason for the change.

### Step 2: Execute SQL Override
Run this in the Supabase SQL Editor.
```sql
-- Replace [JOB_ID] and [NEW_VALUE] as needed
UPDATE public.jobs
SET 
    service_type = '[NEW_SERVICE_TYPE]', -- e.g., 'car_lock_programming'
    job_date = '[NEW_DATE]',             -- e.g., '2026-03-15'
    updated_at = NOW()
WHERE id = '[JOB_ID]';
```

### Step 3: Log the Action
Until the `audit_logs` table is implemented in V2, add a note to the `admin_notes` or record the action in the `dirc_log.md` if it relates to system integrity.

---

## 2. Managing Correction Requests
The Admin can now manage correction requests directly within the Keystone Terminal.

### Procedure (In-App)
1.  **Authorization:** Ensure you are logged into an account with the `admin` role.
2.  **Navigation:** Go to the **Profile** tab and look for the **ADMIN DASHBOARD** section.
3.  **Review:** Tap on **PENDING CORRECTIONS**.
4.  **Execute:** Review the technician's reason, then tap **APPROVE** (to automatically update the job) or **REJECT** (to dismiss).

### SQL Fallback (Manual)
If the app is inaccessible, use these queries in the Supabase SQL Editor.
## 3. Emergency Cache Wipe
If a technician's Hive storage is corrupted and they cannot open the app:
1. Instruct the technician to go to **Android Settings > Apps > Keystone**.
2. Tap **Storage & Cache**.
3. Tap **Clear Storage**.
4. Re-open the app and log in again. All data will re-sync from Supabase.
