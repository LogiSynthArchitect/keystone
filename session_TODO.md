# Session TODO — Audit Items

> **Status:** Audit complete. Architecture design approved. Implementation in progress.
> 10 gaps identified + 2 secondary fractures resolved. See sections below.

---

## P1 — Sync Pipeline

### [ ] Poison Pill: Per-job isolation in sync loop
`_syncChildEntities()` errors crash the entire `for` loop. Fix: wrap each child sync in its own `try/catch`.

**Also:** Remove the silent `catch (e) { debugPrint(...) }` in `_syncChildEntities` — let it throw.

**Also:** Move `syncStatus = 'synced'` to **after** child sync completes, not before.

### [ ] Network vs. Deterministic error differentiation
Simply marking `failed` on every exception destroys background sync — a 3-second network drop marks the job dead. In the per-job catch in `syncPendingJobs`:
- **Transient** (TimeoutException, SocketException, NetworkException not wrapping Postgrest) → keep `pending`, log, `continue`
- **Deterministic** — PostgrestException (constraint violation, FK error) → mark `syncStatus = failed` with error message, `continue`
- **Undetermined** (generic Exception) → keep `pending` (safer to retry than to hard-fail)

**Prerequisite:** Unwrap PostgrestException from NetworkException in remote datasources.

### [ ] 401/403 Auth expiry — abort entire loop, don't fail jobs
401 JWT expiry or 403 Forbidden from Supabase is a **system-level transient**, not a job-level data error. If the per-job catch detects a PostgrestException with code 401/403:
- `break` the sync loop immediately
- Do NOT mark any job as `failed`
- All remaining jobs stay `pending`
- Trigger token refresh / sign-out so user re-authenticates

This prevents a queue of 50 valid jobs from all being marked `failed` when the JWT expired during an offline period.

### [ ] Status Transition Contradiction in `editJob()` + UX gating
`editJob()` (L442-494) only validates `payment_status` transitions (L446-449). It does NOT call `JobEntity.validateStatusTransition()`. The Edit screen places `status` in the changes map → `EditJobUsecase.call()` → `_repository.editJob()`. Neither the use case nor the repo method gates status changes. `updateJobStatus()` DOES gate correctly (L500) but the Edit screen bypasses that path.

**Part 1 — Backend gate:** In `editJob()`, add `validateStatusTransition()` call when `status` is in the changes map:
```dart
if (changes.containsKey('status')) {
  final error = JobEntity.validateStatusTransition(existing.status, changes['status'] as String);
  if (error != null) throw Exception(error);
}
```

**Part 2 — UX prevention (critical):** Without this, the UI offers backward moves, the user confirms (the Edit screen's `_buildStatusStep()` L945-971 even helpfully resets payment to unpaid), then the backend throws a hard Exception. User gets a red snackbar after the UI told them the action was valid.

**Fix:** Pass `currentJobStatus` to `JobStepStatus` and filter the status chip options. In `_buildStatusSelector()`, compute `allowedTargets` using `validateStatusTransition(currentStatus, option)`. Disable/non-tappable when the transition is invalid:

```dart
// In JobStepStatus, optional currentJobStatus parameter
final isAllowed = currentJobStatus == null || 
  JobEntity.validateStatusTransition(currentJobStatus, opt.$1) == null;
// Chip: onTap onStatusChanged(opt.$1) only if isAllowed
// Visual: dimmed with no tap handler when !isAllowed
```

In the Edit screen: pass the original job's status (from `_initFromJob`) as `currentJobStatus`. In the Create wizard: don't pass it (all statuses valid for new jobs).

### [ ] Delete-All Atomic Trap (all 4 child types) + orphan reconciliation
`saveParts()` (L584-597): deletes all old parts (L585) THEN saves new (L586-588). Crash between these two lines permanently destroys child data — Hive has no transaction rollback. Same pattern in `saveHardwareItems()` (L566-579), `saveServices()` (L542-555), `saveExpenses()` (L608-621).

**Compounding factor:** `editJob()` (parent save) happens before any child replacement (`_onSave()` L287→L311-314). If crash during the save* chain, parent is saved with no children. The previously designed `subEntitiesSaved` recovery pipeline won't know which child types were lost because individual child types aren't tracked.

**⚠️ Secondary fracture (caught by reviewer):** Save-first-then-delete creates orphans that share the same `jobId` as legit items. On crash between saveAll and deleteAll, the UI queries by `jobId` and returns BOTH old + new children. Combined with COGS delta logic (Fix #3), the inventory deduction for new items completed, but the old items were never restored. Ghost UI + **permanent inventory corruption**.

**⚠️ Tertiary fracture (caught by reviewer):** Absolute stock targets (`expectedStock = 7`) in the WAL destruction. If a background sync pushes 50 Deadbolts while the app is closed, the startup hook reads the stale WAL, computes `delta = 7 - 57 = -50`, and destroys the new shipment. Absolute targets are unsafe in an offline-first system with background updates.

**Fix — Cross-box WAL with deterministic transaction IDs:**
1. WAL records **relative delta** (e.g., `+2 Deadbolts`) bound to a unique `transactionId`
2. `InventoryItemEntity` tracks `appliedTransactionIds: List<String>`
3. `adjustStock()` checks `appliedTransactionIds` before applying — if the transaction ID is already recorded, skip (idempotent)
4. WAL is written BEFORE any mutations; cleared AFTER all mutations complete
5. Startup `reconcilePendingEdits()` hook replays orphan deletions + inventory deltas for any un-cleared WAL entries

**Implementation status:**
- ✅ `InventoryItemEntity` + `InventoryItemModel`: added `appliedTransactionIds`
- ✅ `adjustStock()`: accepts optional `transactionId`, guards against double-apply
- ✅ `PendingEditTransaction` model: created in `job_logging/data/models/`
- ✅ `reconcilePendingEdits()`: startup hook in `core/recovery/`, called from `main.dart`
- ✅ `replacePartsWithCogs()`: WAL-aware child replacement method in `JobRepository`
- ✅ `deleteKeys()`: added to all 4 child local datasources
- 🔲 Services/hardware/expenses: converted to save-first-then-delete (done, no COGS needed)
- 🔲 Connect `replacePartsWithCogs` + `adjustStock` in `edit_job_screen.dart` `_onSave()`

### [ ] `subEntitiesSaved` flag + visible recovery (no ghost state)
Without it, an orphaned job (crashed before child saves) is identical to a legitimately empty job. `_syncChildEntities` queries empty boxes, returns success, parent gets `synced`. Silent data loss.

Fix:
1. Add `subEntitiesSaved: bool` to `JobEntity` and `JobModel` (default `true` for existing records).
2. In `LogJobNotifier.save()`: set `false` before the first sub-entity write, `true` only after all complete.
3. `getPendingJobs()` gates on `subEntitiesSaved == true`.
4. **NO 24h auto-delete and NO silent skip under 24h.** Show orphaned jobs in the job list with a distinct "Incomplete" badge. User can tap to see what's missing or explicitly delete. Full transparency, no ghost state.

---

## P1b — Recovery Pipeline

### [ ] Dedicated RecoverySaveUsecase (not Create or Edit)
Routing recovery through `LogJobNotifier.save()` or `LogJobNotifier.update()` creates type pollution — neither pipeline was designed for incomplete creation states.

**Architecture:** New `RecoverySaveUsecase` with item-level UUID diffing:
1. Accept jobId + full set of sub-entity payloads (parts, services, expenses, photos)
2. For each child type, load existing items from Hive, index by UUID
3. Incoming items whose UUIDs already exist in Hive → **update in-place** (with COGS delta if part quantity changed)
4. Incoming items with fresh UUIDs (net-new from recovery session) → **save + deduct**
5. Terminal action: flip `subEntitiesSaved` to `true`
6. Does NOT touch: `syncStatus`, `syncErrorMessage`, creation timestamps

**Avoid these rejected approaches:**
- ❌ Collection-level block (`existing.isNotEmpty → continue`) — skips net-new items added during recovery
- ❌ `skipAutoCogs: true` flag — prevents double-deduction of existing items but also skips deduction of genuinely new items
- ❌ Routing through Edit pipeline — Edit doesn't know how to flip `subEntitiesSaved`, creating a secondary state resolution problem every time Edit completes

---

## P2 — Business Logic

### [ ] Recurring Blocked for New Customers
Line 379 blocks save if `_isRecurring && _finalCustomerId == null`. Fix: remove block, at line 647 use `job.customerId` from the returned JobEntity.

### [ ] Name Mismatch on "Keep What You Typed"
Phone matches existing customer but tech typed different name. Fix: always use the matched customer's name. Remove the "Keep my name" option.

### [ ] ₵0 Warranty Block
Line 394 hard-blocks completed jobs with ₵0. Fix: change to a confirm dialog ("Free service — continue?") instead of hard block.

### [ ] Auto-COGS Never Reverses (edit + delete)
Inventory deducted on initial save but never adjusted on edit or restored on delete.

- **Delete/Archive:** Already handled by `archive()` (job_providers.dart L459-530) which restores stock for archived jobs via `invRepo.adjustStock()`.
- **Edit:** `_onSave()` calls `saveParts()` which does deleteAll→saveAll with zero inventory comparison. Changing 5 Deadbolts → 3 never returns the 2 removed to inventory. Existing P2 item covers this: compute delta between old and new quantities per auto-cogs item, adjust stock accordingly as part of edit save.

### [ ] Admin Correction Desync + batch_sync_jobs overwrite protection
Two separate problems:

**Problem A — Online approval (no local write-back):** `approveRequest()` (correction_request_repository_impl.dart L48-57) writes `service_type` and `job_date` to Supabase only — no local Hive update. `AdminRequestsNotifier.approve()` (job_providers.dart L122-132) invalidates `jobDetailProvider`, but `getJobById()` reads from local Hive which still has the OLD values.

**Problem B — Offline scenario (batch_sync_jobs overwrites admin correction):** Admin approves from web dashboard while tech is offline. Tech edits job locally. `syncPendingJobs()` pushes through `batch_sync_jobs`. The RPC's `ON CONFLICT (id) DO UPDATE SET` (v2_complete_schema L265) includes `service_type = EXCLUDED.service_type`, overwriting admin's correction with stale mobile data.

**⚠️ Secondary fracture (caught by reviewer):** Hardcoding `service_type` exclusion from ON CONFLICT is whack-a-mole. Any field Admin touches from the web dashboard is vulnerable. Additionally, blanket `correction_fields = '{}'` on the next direct `updateJob()` destroys concurrent isolation — if Admin locks both `[location, notes]` and tech only edits `notes`, wiping the entire array leaves `location` vulnerable to stale sync from another device.

**Fix — `correction_fields TEXT[]` with per-field `array_remove`:**
- `approve_correction_request` RPC: set `correction_fields` to the keys of `p_updates` (the corrected field names)
- `batch_sync_jobs` ON CONFLICT: each field's `SET` clause checks `correction_fields @> ARRAY['field_name']`. If locked, skip; if mobile value matches server, `array_remove(correction_fields, 'field_name')` — auto-clearing per-field without wiping the entire array
- Direct `updateJob()` (online edit via `editJob` → `_remote.updateJob`): clears only the fields the user actually changed, never the entire array

**Implementation status:**
- ✅ SQL migration created: `20260529000001_batch_sync_occ.sql`
  - Adds `correction_fields TEXT[] DEFAULT '{}'` to jobs table
  - Updates `batch_sync_jobs` with conditional `CASE` per field + `array_remove` auto-clear
  - Updates `approve_correction_request` to populate `correction_fields`
- 🔲 Fix A (local write-back for online admin approval) still pending

---

## Rejected as Over-engineered

| Item | Why |
|------|------|
| Retry counter with threshold | Transient vs deterministic differentiation in the catch block makes a counter unnecessary. Transient → stays `pending`. Deterministic → goes to `failed`. |
| Quarantine tab | `subEntitiesSaved == false` jobs appear in the main job list with an "Incomplete" badge. `syncStatus == failed` jobs appear with a "Sync failed" badge. Same list, distinct badges. |
| Full SQLite/drift migration | The `subEntitiesSaved` flag + sync gate covers the ACID gap adequately. |

## Rejected — Verified False

| Item | Why |
|------|------|
| ID Mutation Danger (duplicate on crash between L270 and L274) | **False under current code.** The `batch_sync_jobs` SQL fix (`local_id = job_record->>'id'`) ensures `localId == serverId` always — the INSERT uses the job's own id as-is, and `ON CONFLICT (id) DO UPDATE RETURNING id` returns the same value. L270 overwrites the same Hive key (no two-record window). L272-275 (`if (localId != serverId)`) never executes. No duplicate scenario exists. See full analysis in reviewer response. |
