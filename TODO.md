# Keystone — Task Tracker

## STRUCTURAL FRACTURES (HIGH priority)

### 1. Generate Due Jobs — No Atomicity
- **File**: `lib/features/recurring_jobs/presentation/providers/recurring_schedule_provider.dart`
- **Issue**: `generateDueJobs()` writes job to Hive (`jobsBox.flush()` line 154) BEFORE advancing schedule's `nextDueDate` (line 159). OS crash between creates permanent job + still-due schedule. No dedup field — `JobModel` has no `scheduleId` or `generatedForDate`. Next tap creates duplicates.
- **Fix**: Idempotent Execution Log (WAL pattern).
  1. Generate a `batch_execution_id` (UUID) before the loop.
  2. Add `generated_from_schedule_id` + `generation_batch_id` columns to `JobModel`.
  3. Write a WAL entry to `_meta` box: `{ type: "schedule_generation", batch_id, target_schedules: [A,B,C], state: "pending" }`.
  4. Execute payload first (write Jobs to jobs box).
  5. Execute trigger second (advance Schedules).
  6. Mark WAL as `completed`.
  7. Recovery: on startup, check WAL for `pending` batches. If batch has matching jobs in `jobs` box, advance schedules and commit. Otherwise restart generation.
- **Why**: This guarantees exactly-once execution. Payload-first + recovery hook eliminates both duplication AND data loss.

### 2. Reminders — No Persistence / Cross-Device
- **File**: `lib/features/reminders/presentation/providers/reminders_provider.dart`
- **Issue**: `dismissedKeys` initialized to `const {}` on every startup — no Hive persistence. `dismissReminder()` in repository is a TODO stub. Each device independently evaluates reminders from shared job list — dismissing on iPhone does nothing for iPad. `_notifiedKeys` static set only prevents double-notification within a single VM session.
- **Fix**: Persist dismissed keys to Hive (same-device restart) + sync to Supabase (cross-device). Implement the TODO in `reminder_repository_impl.dart`.

### 3. Data Export — No Media Handling
- **File**: `lib/core/services/data_export_service.dart`
- **Issue**: JSON export dumps raw Hive maps (URLs as strings, no binary files). CSV exports explicitly omit all media columns — only text fields (serviceType, status, amount, location, notes). Photos/videos/docs live in Supabase Storage behind RLS — not exportable.
- **Fix**: Download media files to temp zip, or document limitation.

## FEATURE GAPS (MEDIUM priority)

### 4. Service Types — No Batch Delete
Cannot delete multiple services at once. Each requires long-press + confirm.

### 5. Recurring Schedules — No Edit Drawer
Only delete via long-press exists. To edit interval/customer, must delete and re-create.

### 6. Reminder Delays — No Minute-Level Granularity
Only hours/days thresholds. No option for 30 minutes or 1 week.

## FEATURE GAPS (LOW priority)

### 7. Category/Pricing — No New Category API
Adding a new category requires a code deployment. No runtime extensibility.

### 8. Icon Picker — Not Filtered by Category
Shows all 24 icons regardless of selected category. Category-relevant icons not highlighted.
