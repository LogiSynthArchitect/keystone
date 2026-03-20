# OPEN BUGS — KEYSTONE V1
### Last Updated: March 20 2026
### Session 29 Update: Added BUG-025 through BUG-031 (all closed)

BUG-001 through BUG-012 all closed (Sessions 24 & 25).
BUG-013 through BUG-024 all closed (Sessions 26–28).
BUG-025 through BUG-031 all closed (Sessions 28B–29).
No open bugs as of March 20 2026.

---

## BUG-001 — Sync Failure Permanently Bricks a Job
**Severity:** High — data loss risk, job becomes permanently orphaned
**Status:** ✅ FIXED (Session 24)

### File
`lib/features/job_logging/data/repositories/job_repository_impl.dart` — lines 73–76

### Root Cause
When `createJob` is called and the device is online but the remote write fails (network blip,
Supabase timeout, etc.), the catch block overwrites the local job record from `sync_status: pending`
to `sync_status: failed`. The background sync engine (`syncPendingJobs`) only retries jobs with
`sync_status: pending`. A `failed` job is never retried — it is permanently stuck.

### Current Code (lines 73–76)
```dart
} catch (e) {
  final errorModel = JobModel.fromJson({...json, 'sync_status': 'failed', 'sync_error_message': e.toString()});
  await _local.saveJob(errorModel);
}
```

### Fix
Remove the catch block body entirely. The initial `model` (line 62) is already saved locally as
`pending` before the online attempt. If the remote call fails, that `pending` record stays intact
and the sync engine will retry it on the next call to `syncPendingJobs`. Only log the error.

```dart
} catch (e) {
  debugPrint('[KS:JOBS] Remote create failed, job stays pending for retry: $e');
}
```

### Test Verification
1. Disable WiFi/mobile data on device.
2. Log a new job.
3. Re-enable data.
4. Pull to refresh on the job list.
5. Expected: job transitions from "Pending" to "Synced" without user intervention.
6. Before fix: job shows a permanent error state / never syncs.

---

## BUG-002 — New Customer Doesn't Appear in Customer List After Job Creation
**Severity:** Medium — confusing UX, tech thinks data was lost
**Status:** ✅ FIXED (Session 24)

### File
`lib/features/job_logging/presentation/providers/job_providers.dart` — line 300

### Root Cause
When a job is logged with a brand-new customer (not an existing one), `LogJobNotifier.save()`
calls `customerListProvider.notifier.incrementJobCount(job.customerId)` (line 300). But
`incrementJobCount` only updates the `totalJobs` counter on an existing list entry — it does not
add the new customer to the list. The new customer is saved to Hive and Supabase, but
`customerListProvider` is never told to reload, so the customer doesn't appear until the user
manually navigates away and back, or restarts the app.

### Current Code (line 300)
```dart
_ref.read(customerListProvider.notifier).incrementJobCount(job.customerId);
```

### Fix
After `incrementJobCount`, also trigger a full refresh of the customer list. This ensures the new
customer (which was written to Hive during `createCustomer`) is loaded into the provider state.

```dart
_ref.read(customerListProvider.notifier).incrementJobCount(job.customerId);
await _ref.read(customerListProvider.notifier).refresh();
```

### Where `refresh()` is defined
Check `lib/features/customer_history/presentation/providers/customer_providers.dart` — the
`CustomerListNotifier` should already have a `refresh()` or `load()` method. Use whichever
triggers a full re-fetch from Hive (not just remote).

### Test Verification
1. Log a new job with a new customer name and phone number.
2. Navigate to the Customer List screen immediately after saving.
3. Expected: the new customer appears in the list.
4. Before fix: customer list is empty or stale until the app restarts.

---

## BUG-003 — Keyboard Dismisses / Focus Lost When Typing "0"
**Severity:** Medium — major usability problem on the job logging form
**Status:** ✅ FIXED (Session 24)

### File
`lib/features/job_logging/presentation/screens/log_job_screen.dart` — line 380

### Root Cause
The `_buildDarkField` helper (a reusable TextField builder) has `onChanged: (_) => setState(() {})`
on every text field. Every keystroke triggers a full `setState`, which rebuilds the entire screen
widget tree. When the screen rebuilds, the focused `TextField` loses its focus context and the soft
keyboard is dismissed. This is especially noticeable when typing "0" because it fires the callback
reliably and the full rebuild is clearly perceptible.

### Current Code (line 380)
```dart
onChanged: (_) => setState(() {}),
```

### Fix
Remove the `onChanged: (_) => setState(() {})` from `_buildDarkField`. Instead, attach a listener
to each `TextEditingController` in `initState()` so the setState is triggered by the controller,
not the field rebuild cycle. Since controllers already hold state, a rebuild is only needed when
the UI must update based on whether a field is empty/filled — which can be driven by the controller
listener pattern.

**Step 1** — Remove `onChanged` from `_buildDarkField`:
```dart
// DELETE this line:
onChanged: (_) => setState(() {}),
```

**Step 2** — In `initState()`, add listeners to each controller that currently drives a visual
state check (e.g., the amount field, notes field, etc.):
```dart
_amountController.addListener(() => setState(() {}));
_notesController.addListener(() => setState(() {}));
// ... any other controller that drives conditional UI
```

**Important:** Only add listeners for controllers whose changes actually affect what is rendered
(e.g., a "clear" button appearing, character count, conditional validation text). If `setState` is
only there for completeness and no visual depends on it, remove it entirely.

### Test Verification
1. Open the Log Job screen.
2. Tap the Amount field. Type "35000". Then type "0".
3. Expected: each keystroke is registered, keyboard stays visible, cursor stays in the field.
4. Before fix: keyboard collapses or focus jumps to the top of the screen on the "0" keypress.

---

## BUG-004 — Archived Jobs Reappear After Next Sync
**Severity:** High — data integrity, technician's archive action is silently undone
**Status:** ✅ FIXED (Session 24)

### File
`lib/features/job_logging/data/repositories/job_repository_impl.dart` — lines 34–41

### Root Cause
When the device is online, `getJobs` fetches all non-archived jobs from Supabase and writes each
one to local Hive storage via `_local.saveJob(m)` (line 37). This `saveJob` is a full overwrite
— it replaces the local record with the remote record. If the technician archived a job while
offline (local record: `is_archived: true, sync_status: pending`), the next online refresh calls
`getJobs`, the remote still returns that job as `is_archived: false`, and `saveJob` overwrites
the local pending-archive state. The job reappears as if it was never archived.

### Current Code (lines 34–41)
```dart
if (isOnline) {
  try {
    final remoteModels = await _remote.getJobs(userId: _userId, limit: limit, offset: offset);
    for (final m in remoteModels) { await _local.saveJob(m); }
  } catch (e) {
    debugPrint('[KS:JOBS] Remote fetch failed, serving from cache: $e');
  }
}
```

### Fix
Before overwriting a local record with the remote version, check if the local version has a
`pending` archive action in flight. If it does, skip the overwrite to preserve the local intent.

```dart
if (isOnline) {
  try {
    final remoteModels = await _remote.getJobs(userId: _userId, limit: limit, offset: offset);
    for (final m in remoteModels) {
      final existing = await _local.getJob(m.id);
      // Don't overwrite a locally-pending archive with the remote stale state
      if (existing != null && existing.isArchived && existing.syncStatus == SyncStatus.pending) {
        continue;
      }
      await _local.saveJob(m);
    }
  } catch (e) {
    debugPrint('[KS:JOBS] Remote fetch failed, serving from cache: $e');
  }
}
```

**Prerequisite:** Verify that `JobLocalDatasource` has a `getJob(String id)` method. If it doesn't,
add one — it should simply do `_box.get(id)` where `_box` is the Hive box for jobs.

### Test Verification
1. While online, log a job (let it sync to `synced`).
2. Disable network. Archive that job.
3. Verify the job disappears from the active job list.
4. Re-enable network. Pull to refresh.
5. Expected: job remains archived (does not reappear).
6. Before fix: job reappears in the active list after refresh.

---

## BUG-005 (Minor) — `getCustomerById` Throws Unhelpful `StateError` When Customer Missing
**Severity:** Low — internal crash, shows a generic error to the user
**Status:** ✅ FIXED (Session 24)

### File
`lib/features/customer_history/data/repositories/customer_repository_impl.dart` — line 51

### Root Cause
In `getCustomerById`, when online, the code fetches all customers and uses `firstWhere` to find
the match. If the customer doesn't exist in the remote list, `firstWhere` throws a `StateError`
("Bad state: No element") instead of a clean `StorageException`. This bubbles up as an unhandled
error with an unhelpful message.

### Current Code (line 51)
```dart
final match = models.firstWhere((m) => m.id == id);
```

### Fix
Replace with `firstOrNull` and handle the null case explicitly with a proper `StorageException`:

```dart
final match = models.where((m) => m.id == id).firstOrNull;
if (match == null) {
  debugPrint('[KS:CUSTOMERS] Customer $id not found in remote list, falling back to local.');
  // Fall through to local lookup below by re-throwing or breaking out of the try block.
  throw core_storage.StorageException(message: 'Customer not found remotely.', code: 'CUSTOMER_NOT_FOUND');
}
await _local.saveCustomer(match);
return match.toEntity();
```

Note: The `catch` block at lines 54–56 already catches any thrown exception and falls through to
the local lookup, so throwing `StorageException` here will correctly trigger the fallback path.
The existing `debugPrint` log in the catch block will surface it.

### Test Verification
1. Delete a customer record directly in Supabase dashboard.
2. On device, navigate to that customer's job detail.
3. Expected: a clean error message ("Customer not found") rather than a crash or "Bad state" error.

---

## BUG-006 — Force `!` on `currentUser` in Three Places
**Severity:** High — guaranteed crash if auth session expires
**Status:** ✅ FIXED (Session 25)

### Files
1. `lib/features/knowledge_base/presentation/providers/notes_providers.dart` — line 168
2. `lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart` — line 148
3. `lib/features/job_logging/data/repositories/correction_request_repository_impl.dart` — line 28

### Root Cause
All three locations use `_supabase.auth.currentUser!.id` (or `ref.read(...).auth.currentUser!.id`).
This is a guaranteed `Null check operator used on a null value` crash if the user's auth session
expires while the app is open. Session expiry is a real scenario on mobile (background for hours,
token refresh fails, Supabase signs out automatically).

### Exact Fix Per Location

**Location 1 — `notes_providers.dart:168` inside `AddNoteNotifier.save()`:**
```dart
// BEFORE:
userId: _supabase.auth.currentUser!.id,

// AFTER:
final userId = _supabase.auth.currentUser?.id;
if (userId == null) throw Exception('Authentication session expired. Please log in again.');
```
Then use `userId` in the `CreateNoteParams(userId: userId, ...)`.

**Location 2 — `job_detail_screen.dart:148` inside `_showCorrectionRequestDialog()`:**
```dart
// BEFORE:
final userId = ref.read(supabaseClientProvider).auth.currentUser!.id;

// AFTER:
final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
if (userId == null) {
  if (context.mounted) KsSnackbar.show(context, message: "Session expired. Please log in again.", type: KsSnackbarType.error);
  return;
}
```

**Location 3 — `correction_request_repository_impl.dart:28` inside `getMyRequests()`:**
```dart
// BEFORE:
.eq('user_id', _supabase.auth.currentUser!.id)

// AFTER:
final uid = _supabase.auth.currentUser?.id;
if (uid == null) throw Exception('Authentication session expired.');
// then:
.eq('user_id', uid)
```

### Test Verification
1. Log in, navigate to Add Note screen. Fill in a note but don't submit.
2. Manually expire session (sign out from another device or wait for token expiry).
3. Tap Save.
4. Expected: user sees "Session expired" error, no crash.
5. Before fix: app crashes with "Null check operator used on a null value".

---

## BUG-007 — `archiveNote` Has No Offline Guard — Note Disappears Permanently
**Severity:** High — data integrity, archived note reappears or disappears incorrectly
**Status:** ✅ FIXED (Session 25)

### File
`lib/features/knowledge_base/data/repositories/knowledge_note_repository_impl.dart` — lines 121–126

### Root Cause
`archiveNote` calls `await _remote.archiveNote(id)` directly as the FIRST thing it does, with no
connectivity check. If the device is offline, this throws immediately. The `NotesListNotifier`
caller at `notes_providers.dart:128–135` catches the exception and sets an error state, but still
removes the note from the UI list (line 131). On next `load()`, the note comes back from Hive
(still `is_archived: false`) and reappears. The archive action is silently lost.

### Current Code (lines 121–126)
```dart
@override
Future<void> archiveNote(String id) async {
  await _remote.archiveNote(id);
  final localNotes = await _local.getNotes();
  final note = localNotes.where((n) => n.id == id).firstOrNull;
  if (note != null) await _local.saveNote(note.copyWith(isArchived: true));
}
```

### Fix
Adopt the same local-first pattern used for jobs. Save locally first with `is_archived: true`,
then attempt remote. If remote fails, the local state is already updated and will persist.

```dart
@override
Future<void> archiveNote(String id) async {
  // 1. Update locally first (offline-first guarantee)
  final localNotes = await _local.getNotes();
  final note = localNotes.where((n) => n.id == id).firstOrNull;
  if (note != null) await _local.saveNote(note.copyWith(isArchived: true));

  // 2. Attempt remote (best-effort, no retry mechanism yet)
  try {
    await _remote.archiveNote(id);
  } catch (e) {
    debugPrint('[KS:NOTES] Remote archiveNote failed, local state preserved: $e');
  }
}
```

### Test Verification
1. Disable network. Archive a note in the Knowledge Base.
2. Expected: note disappears from the list immediately and stays gone.
3. Re-enable network. Navigate away and back.
4. Expected: note remains archived (does not reappear).
5. Before fix: offline archive is lost — note reappears after next load.

---

## BUG-008 — `batch_sync_jobs` RPC Returns `local_id: null` — Offline Jobs Never Marked Synced
**Severity:** High — sync state inconsistency, offline jobs never confirmed as synced in Hive
**Status:** ✅ FIXED — already correct in live DB (confirmed via SQL audit, Session 25)

### File (SQL)
`supabase/migrations/20260316013206_remote_schema.sql` — lines 173 (RPC `batch_sync_jobs`)

### Root Cause
The Flutter client sends job payloads where each job has `"id": "<uuid>"` (the local UUID).
The RPC response builds: `jsonb_build_object('local_id', job_record->>'local_id', ...)`.
But there is no `local_id` key in the payload — only `id`. So `job_record->>'local_id'` is always
`NULL` for every job.

In Flutter's `syncPendingJobs()` (`job_repository_impl.dart:188`):
```dart
final localId = syncedItem['local_id'] as String?;
if (localId == null) continue;  // ← ALWAYS hits this for every job
```
Every synced job is skipped. Jobs are written to the server correctly (the INSERT succeeds) but
Hive is never updated. Jobs stay `pending` in Hive until the next `getJobs` call fetches them
back from the server and overwrites the local record.

**Visual impact:** after syncing offline jobs, the UI still shows them as "Pending" for the duration
of the current session. They only show "Synced" after the next pull-to-refresh.

### Fix — SQL (apply to both Testing and Production)
```sql
CREATE OR REPLACE FUNCTION "public"."batch_sync_jobs"("p_user_id" "uuid", "p_jobs" "jsonb")
RETURNS "jsonb" LANGUAGE "plpgsql" SECURITY DEFINER AS $$
DECLARE
  job_record JSONB;
  new_job_id UUID;
  synced_jobs JSONB := '[]';
  failed_jobs JSONB := '[]';
BEGIN
  FOR job_record IN SELECT * FROM jsonb_array_elements(p_jobs)
  LOOP
    BEGIN
      INSERT INTO jobs (id, user_id, customer_id, service_type, job_date, location, notes, amount_charged, sync_status)
      VALUES (
        (job_record->>'id')::UUID,
        p_user_id,
        (job_record->>'customer_id')::UUID,
        (job_record->>'service_type')::service_type,
        (job_record->>'job_date')::DATE,
        job_record->>'location',
        job_record->>'notes',
        (job_record->>'amount_charged')::DECIMAL,
        'synced'
      )
      ON CONFLICT (id) DO UPDATE SET
        sync_status = EXCLUDED.sync_status,
        updated_at = NOW()
      RETURNING id INTO new_job_id;

      -- FIX: was job_record->>'local_id' (always NULL). Now uses 'id' which is what Flutter sends.
      synced_jobs := synced_jobs || jsonb_build_object(
        'local_id', job_record->>'id',
        'server_id', new_job_id,
        'sync_status', 'synced'
      );
    EXCEPTION WHEN OTHERS THEN
      failed_jobs := failed_jobs || jsonb_build_object('local_id', job_record->>'id', 'error', SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object('synced', synced_jobs, 'failed', failed_jobs);
END;
$$;
```
Apply this to **both** Testing and Production Supabase projects via SQL Editor or a new migration.

### Test Verification
1. Create a job while offline.
2. Re-enable network. Pull to refresh.
3. Expected: job transitions from "Pending" to "Synced" without needing a second refresh.
4. Before fix: job shows "Pending" after the first refresh, only synced after a second refresh.

---

## BUG-009 — `_authUserId` Silently Returns Empty String Instead of Throwing
**Severity:** Medium — silent failure, all profile queries use wrong user_id
**Status:** ✅ FIXED (Session 25)

### File
`lib/features/technician_profile/data/repositories/profile_repository_impl.dart` — line 16

### Root Cause
```dart
String get _authUserId => _supabase.auth.currentUser?.id ?? '';
```
If auth session is null, this returns `''` (empty string). Unlike all other repos which throw
`StorageException('AUTH_MISSING')`, this silently continues. `getProfile('')` queries Supabase
with `user_id = ''`, returns null, falls back to cache — which appears to work but is wrong.
The real danger is `uploadPhoto`: it calls `_remote.uploadPhoto(userId: _authUserId, ...)` which
would write to `profile-photos//filename` — the folder is named `''`. This could conflict with
other users' uploads or fail the storage RLS policy.

### Fix
Change to throw, matching the pattern in all other repositories:
```dart
String get _authUserId {
  final id = _supabase.auth.currentUser?.id;
  if (id == null) throw Exception('Authentication session expired. Please log in again.');
  return id;
}
```

### Test Verification
1. With expired auth, navigate to Profile screen.
2. Expected: user sees session-expired error, not a silent empty profile.

---

## BUG-010 — Offline Notes Are Never Re-Synced After Connectivity Restores
**Severity:** Medium — data loss, notes created offline stay in limbo forever
**Status:** ✅ FIXED (Session 25)

### File
`lib/features/knowledge_base/data/repositories/knowledge_note_repository_impl.dart` — lines 64–92

### Root Cause
`createNote` saves locally as `sync_status: pending` when offline. This is correct.
But there is no `syncPendingNotes()` function anywhere in the app. The `KnowledgeNoteLocalDatasource`
has `getPendingNotes()` (line 79) — but nothing ever calls it. The `refresh()` in
`NotesListNotifier` calls `load()` → `getNotes()`, which tries remote first. If online, it fetches
from remote (which doesn't have the pending note) and overwrites local — the pending note is now
visible in local Hive but the next remote fetch would overwrite with the server list (no pending note).

**Net effect:** a note created while offline is visible immediately (from Hive) but is never sent
to Supabase. When the device goes online and `load()` is called, the remote list is fetched and
saved to Hive (overwriting the pending note). The note disappears.

### Fix
Two parts:

**Part 1 — Create `syncPendingNotes()` in `KnowledgeNoteRepositoryImpl`:**
```dart
Future<void> syncPendingNotes() async {
  final pending = await _local.getPendingNotes();
  if (pending.isEmpty) return;
  for (final note in pending) {
    try {
      final serviceTypeDb = note.serviceType != null
          ? _serviceTypeToDb(note.serviceType!)
          : null;
      final remoteModel = await _remote.createNote({
        'user_id': _userId,
        'title': note.title,
        'description': note.description,
        'tags': note.tags,
        'photo_url': note.photoUrl,
        'service_type': serviceTypeDb,
        'is_archived': false,
      });
      await _local.saveNote(remoteModel);
    } catch (e) {
      debugPrint('[KS:NOTES] syncPendingNotes failed for ${note.id}: $e');
    }
  }
}
```

**Part 2 — Add to domain repository interface** (`KnowledgeNoteRepository`), **create use case**
(`SyncPendingNotesUsecase`), and **call from `NotesListNotifier.refresh()`** before `load()`.

**Part 3 — Fix `getNotes()` to not overwrite pending local notes:**
Before `await _local.saveNotes(remoteModels)`, filter out any local notes that have
`sync_status == 'pending'` from being overwritten by the remote list.

### Test Verification
1. Disable network. Create a note. Verify it appears.
2. Re-enable network. Pull to refresh in Knowledge Base.
3. Expected: note still visible AND now shows as synced in Hive.
4. Before fix: note disappears after going online.

---

## BUG-011 — `getCustomerById` Fetches All 1000 Customers to Find One
**Severity:** Low — performance issue, slow for large customer lists
**Status:** ✅ FIXED (Session 25)

### File
`lib/features/customer_history/data/repositories/customer_repository_impl.dart` — line 50

### Root Cause
```dart
final models = await _remote.getCustomers(userId: _userId, limit: 1000, offset: 0);
final match = models.where((m) => m.id == id).firstOrNull;
```
This fetches ALL customers to find one by ID. With 1000 customers, this is a large unnecessary
payload. Supabase can filter at the DB level.

### Fix
Add a `getCustomerById(String id)` method to `CustomerRemoteDatasource`:
```dart
Future<CustomerModel?> getCustomerById(String id) async {
  final data = await _supabase
      .from('customers')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return CustomerModel.fromJson(data);
}
```
Then use it in `CustomerRepositoryImpl.getCustomerById()`:
```dart
if (await _connectivity.isConnected) {
  try {
    final model = await _remote.getCustomerById(id);
    if (model == null) throw core_storage.StorageException(message: 'Customer not found.', code: 'CUSTOMER_NOT_FOUND');
    await _local.saveCustomer(model);
    return model.toEntity();
  } catch (e) {
    debugPrint('[KS:CUSTOMERS] Remote getById failed, falling back to local: $e');
  }
}
```

---

## BUG-012 — Missing `flush()` in Customer and Note Local Datasources
**Severity:** Low — potential data loss on hard app crash (very rare)
**Status:** ✅ FIXED (Session 25)

### Files
- `lib/features/customer_history/data/datasources/customer_local_datasource.dart` — line 16
- `lib/features/knowledge_base/data/datasources/knowledge_note_local_datasource.dart` — line 11

### Root Cause
`JobLocalDatasource.saveJob()` explicitly calls `await _box.flush()` after `box.put()` to force
immediate disk write. `CustomerLocalDatasource` and `KnowledgeNoteLocalDatasource` do not.
On a hard crash (OOM kill, phone restarted mid-write), unflushed Hive writes can be lost since
they live in OS write buffers. For jobs — where data integrity is critical — flush is present.
For customers and notes it is missing.

### Fix
Add `await box.flush();` after `await box.put(...)` in both datasources:

**`customer_local_datasource.dart:16`:**
```dart
Future<void> saveCustomer(CustomerModel customer) async {
  final box = HiveService.customers;
  await box.put(customer.id, customer.toJson());
  await box.flush(); // Force immediate disk persistence
}
```

**`knowledge_note_local_datasource.dart:11`:**
```dart
Future<void> saveNote(KnowledgeNoteModel note) async {
  try {
    await _box.put(note.id, note.toJson().cast<String, dynamic>());
    await _box.flush(); // Force immediate disk persistence
  } catch (e) {
    throw StorageException(...);
  }
}
```

---

## Summary Table

| ID      | File                                          | Severity | Status  | Root Cause (1-line)                                              |
|---------|-----------------------------------------------|----------|---------|------------------------------------------------------------------|
| BUG-001 | `job_repository_impl.dart` line 73            | High     | ✅ Fixed | Failed remote create overwrites `pending` with `failed`          |
| BUG-002 | `job_providers.dart` line 300                 | Medium   | ✅ Fixed | `customerListProvider` never refreshed after new customer create |
| BUG-003 | `log_job_screen.dart` line 380                | Medium   | ✅ Fixed | `onChanged: setState` causes full rebuild, kills keyboard focus  |
| BUG-004 | `job_repository_impl.dart` lines 34–41        | High     | ✅ Fixed | Remote fetch overwrites pending-archive local state              |
| BUG-005 | `customer_repository_impl.dart` line 51       | Low      | ✅ Fixed | `firstWhere` throws `StateError` instead of clean exception      |
| BUG-006 | 3 files (see above)                           | High     | ✅ Fixed | `currentUser!` force unwrap crashes on session expiry            |
| BUG-007 | `knowledge_note_repository_impl.dart` line 121| High     | ✅ Fixed | `archiveNote` no offline guard — note undone on next load        |
| BUG-008 | SQL RPC `batch_sync_jobs`                     | High     | ✅ Fixed | Already correct in live DB (confirmed via SQL audit)             |
| BUG-009 | `profile_repository_impl.dart` line 16        | Medium   | ✅ Fixed | `_authUserId` returns `''` instead of throwing on null session   |
| BUG-010 | `knowledge_note_repository_impl.dart` line 64 | Medium   | ✅ Fixed | No `syncPendingNotes()` — offline notes lost on next remote fetch|
| BUG-011 | `customer_repository_impl.dart` line 50       | Low      | ✅ Fixed | `getCustomerById` fetches all 1000 customers to find one         |
| BUG-012 | `customer_local_datasource.dart` + notes ds   | Low      | ✅ Fixed | Missing `flush()` — customers/notes not force-persisted to disk  |

---

---

## BUG-013 — `onChanged: setState` Keyboard Focus Loss on 3 More Screens
**Severity:** High — same root cause as BUG-003, affects customer, notes and profile forms
**Status:** Open

### Files
1. `lib/features/customer_history/presentation/screens/add_customer_screen.dart` — `_buildDarkField` line ~325
2. `lib/features/knowledge_base/presentation/screens/add_note_screen.dart` — `_buildDarkField` line ~358
3. `lib/features/technician_profile/presentation/screens/edit_profile_screen.dart` — `_buildInputField` line ~297

### Root Cause
BUG-003 fixed `log_job_screen.dart` but the same `onChanged: (_) => setState(() {})` pattern
exists in three other screens that have their own `_buildDarkField` or `_buildInputField` helpers.
Every keystroke triggers a full rebuild → keyboard collapses, user loses focus, has to tap the
field again to continue typing. Confirmed worst when typing "0".

### Fix (same pattern as BUG-003 fix)
For each screen:

**Step 1** — Remove `onChanged: (_) => setState(() {})` from the `_buildDarkField` /
`_buildInputField` helper method.

**Step 2** — In each screen's `initState()`, add a listener to every controller whose value
drives a visual change (e.g. Save button enabled state, character count, conditional error):

```dart
// add_customer_screen.dart initState:
_nameController.addListener(() => setState(() {}));
_phoneController.addListener(() => setState(() {}));
_locationController.addListener(() => setState(() {}));
_notesController.addListener(() => setState(() {}));

// add_note_screen.dart initState:
_titleController.addListener(() => setState(() {}));
_descriptionController.addListener(() => setState(() {}));

// edit_profile_screen.dart initState:
_nameController.addListener(() => setState(() {}));
_bioController.addListener(() => setState(() {}));
_whatsappController.addListener(() => setState(() {}));
```

**Step 3** — Remove listeners in `dispose()`:
```dart
_nameController.removeListener(() => setState(() {}));
// ... same for each
```
Or simply call `_nameController.dispose()` in dispose (Dart auto-removes listeners on dispose).

### Test Verification
1. Open Add Customer screen. Tap phone field. Type "0553".
2. Expected: keyboard stays open, cursor stays in field after every keystroke.
3. Before fix: focus drops after "0", user must tap field again.

---

## BUG-014 — Phone Fields Missing Ghana Format Enforcement on 3 Screens
**Severity:** High — invalid phone numbers stored, WhatsApp links break silently
**Status:** Open

### Files
1. `lib/features/customer_history/presentation/screens/add_customer_screen.dart` — phone field
2. `lib/features/job_logging/presentation/screens/log_job_screen.dart` — new customer phone field
3. `lib/features/technician_profile/presentation/screens/edit_profile_screen.dart` — WhatsApp field

### Root Cause
These three phone fields have `keyboardType: TextInputType.phone` but no `inputFormatters`
and no format validation. A user can type "+233-024 123 4567", "abc", or "123" and it will be
accepted and saved. The WhatsApp launcher builds a URL from the raw phone string — if the format
is wrong, WhatsApp opens but shows "invalid number". The correct pattern already exists in
`phone_entry_screen.dart` (lines 177–179) but was not applied to these three screens.

### Correct Pattern (from `phone_entry_screen.dart`)
```dart
keyboardType: TextInputType.phone,
inputFormatters: [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),
],
```

And validate before save:
```dart
// Ghana numbers: 10 digits, starts with 0
final phone = _phoneController.text.trim();
if (phone.length != 10 || !phone.startsWith('0')) {
  // show error: "Enter a valid 10-digit Ghana number starting with 0"
  return;
}
```

### Apply To
- `add_customer_screen.dart`: phone field + validation before calling `notifier.save()`
- `log_job_screen.dart`: new customer phone field + validation in Step 1
- `edit_profile_screen.dart`: WhatsApp number field + validation before `notifier.save()`

### Test Verification
1. Open Add Customer. Tap phone field. Try typing letters — keyboard shows digits only.
2. Try typing 11 digits — stops at 10.
3. Enter "0553891956". Tap Save. Succeeds.
4. Enter "553891956" (9 digits, no leading 0). Tap Save. Shows error: invalid format.

---

## BUG-015 — No Visual Sync Status Indicator (Auto-Sync is Invisible)
**Severity:** Medium — user has no feedback that background sync is happening or pending
**Status:** Open

### Files
- `lib/features/job_logging/presentation/screens/job_list_screen.dart`
- `lib/features/job_logging/presentation/providers/job_providers.dart` — `pendingCount` getter exists but unused in UI

### Root Cause
`JobListState.pendingCount` (job_providers.dart) counts jobs with `sync_status == pending`.
This number is calculated but never displayed anywhere. The user has no way to know:
- That a sync is happening in the background
- That X jobs are waiting to sync to Supabase
- When the last sync completed successfully

The `isLoading` spinner only shows during initial load — not during background sync
(`refresh()` → `syncPendingJobs()` runs silently).

### Fix
Add a small sync status chip at the top of the job list. Two states:

**State A — pending jobs exist:**
```dart
// Show inside job list header, near the job count
if (state.pendingCount > 0)
  Row(children: [
    Icon(Icons.sync, size: 14, color: AppColors.accent500),
    SizedBox(width: 4),
    Text(
      '${state.pendingCount} pending sync',
      style: AppTextStyles.label.copyWith(color: AppColors.accent500),
    ),
  ]),
```

**State B — all synced:**
```dart
// When pendingCount == 0 and not loading, show a brief "All synced ✓"
// or just show nothing (clean UI)
```

Also add a `isSyncing` bool to `JobListState` and set it to `true` during `refresh()` calls,
`false` when done. Show a small pulsing dot or spinner while syncing.

### Test Verification
1. Create a job while offline.
2. Navigate to job list.
3. Expected: "1 pending sync" indicator visible near job count.
4. Re-enable network, pull to refresh.
5. Expected: indicator disappears once sync completes.

---

## BUG-016 — Text Fields Missing `maxLength` — Unbounded Input on All Forms
**Severity:** Medium — users can paste arbitrarily long text, crashes DB constraints
**Status:** Open

### Root Cause
The database enforces field length limits via `CHECK` constraints and `varchar(N)` columns.
But the app has no client-side `maxLength` on most fields. A user who pastes a 5000-character
paragraph into the Notes field will get a Supabase error on sync — with no feedback on why.
The DB column sizes are the authoritative limits; the app should enforce them client-side first.

### Fields and Their DB Limits (from schema)

| Screen | Field | DB Limit | Current maxLength in app |
|--------|-------|----------|--------------------------|
| Add Customer | Name | varchar(100) | None |
| Add Customer | Location | varchar(255) | None |
| Add Customer | Notes | varchar(1000) | None |
| Log Job | Customer Name | varchar(100) | None |
| Log Job | Location | varchar(255) | None |
| Log Job | Notes | varchar(2000) | None |
| Edit Profile | Display Name | varchar(100) | None |
| Edit Profile | Bio | varchar(300) | None |
| Add Note | Title | varchar(200) | None |
| Add Note | Description | text (no limit) | None |
| Follow-up Message | Message | varchar(1000) | None |
| Correction Request | Reason | text (no limit) | None |

### Fix
Add `maxLength` to each `TextField` matching the DB column size:
```dart
// Example for customer name field:
TextField(
  controller: _nameController,
  maxLength: 100,                   // matches varchar(100) in DB
  maxLengthEnforcement: MaxLengthEnforcement.enforced,
  // ... rest of decoration
)
```

Set `buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null`
if you don't want the character counter visible in the UI (keeps the dark aesthetic clean).

### Test Verification
1. Open Add Customer. Paste a 500-character string into the Name field.
2. Expected: input stops at 100 characters. No DB error on save.

---

## BUG-017 — Amount Field Accepts Negative Numbers and Invalid Input
**Severity:** Medium — negative amounts could be stored; no client-side guard
**Status:** Open

### File
`lib/features/job_logging/presentation/screens/log_job_screen.dart` — amount field (~line 291)

### Root Cause
The amount field uses `keyboardType: TextInputType.number` but has no `inputFormatters`.
The DB has `CHECK (amount_charged >= 0)` which would reject negatives at the server — but
the error is caught silently during sync and logged only to console. The user would see the
job saved locally but the amount never syncing correctly.

`KsTextField` widget already has a correct amount formatter:
`RegExp(r'^\d+\.?\d{0,2}')` — but the job log screen uses its own `_buildDarkField`
helper which doesn't apply it.

### Fix
Add `inputFormatters` to the amount field:
```dart
// In the amount _buildDarkField call, add formatters:
inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
],
```
This allows digits and up to 2 decimal places, and prevents `-`, `+`, `e`, letters.

Also add validation before save:
```dart
final amount = double.tryParse(amountController.text.trim());
if (amount != null && amount <= 0) {
  // show: "Amount must be greater than 0"
  return;
}
```

### Test Verification
1. Open Log Job. Tap amount field. Try typing "-50" — the `-` is rejected.
2. Try typing "35.999" — stops at "35.99" (2 decimal places).
3. Enter "350". Save. Job saved with GHS 350.

---

## BUG-018 — Search Fields Double-Update State (Riverpod + setState Both Called)
**Severity:** Low — performance issue, causes unnecessary rebuilds on search
**Status:** Open

### Files
1. `lib/features/job_logging/presentation/screens/job_list_screen.dart` — search field `onChanged`
2. `lib/features/customer_history/presentation/screens/customer_list_screen.dart` — search `onChanged`
3. `lib/features/knowledge_base/presentation/screens/notes_list_screen.dart` — search `onChanged`

### Root Cause
Each search field's `onChanged` calls both the Riverpod notifier AND `setState(() {})`.
Riverpod already triggers a rebuild when the provider state changes. The `setState` is
redundant and causes a second rebuild on every keystroke. On slower devices this is
noticeable as a stutter during typing in the search bar.

### Fix
Remove the `setState(() {})` call from each search field's `onChanged`. The Riverpod
provider rebuild is sufficient:

```dart
// BEFORE (job_list_screen.dart):
onChanged: (val) {
  ref.read(jobListProvider.notifier).setSearchQuery(val);
  setState(() {}); // ← REMOVE THIS
},

// AFTER:
onChanged: (val) {
  ref.read(jobListProvider.notifier).setSearchQuery(val);
},
```
Apply same change to customer list and notes list search fields.

### Test Verification
1. Open Job List. Search for any term. Typing should feel smooth with no stutter.

---

## Updated Summary Table

| ID      | File(s)                                          | Severity | Status   | Root Cause                                                     |
|---------|--------------------------------------------------|----------|----------|----------------------------------------------------------------|
| BUG-001 | `job_repository_impl.dart` line 73               | High     | ✅ Fixed | Failed remote create overwrites `pending` with `failed`        |
| BUG-002 | `job_providers.dart` line 300                    | Medium   | ✅ Fixed | `customerListProvider` not refreshed after new customer create |
| BUG-003 | `log_job_screen.dart` line 380                   | Medium   | ✅ Fixed | `onChanged: setState` full rebuild kills keyboard focus        |
| BUG-004 | `job_repository_impl.dart` lines 34–41           | High     | ✅ Fixed | Remote fetch overwrites pending-archive local state            |
| BUG-005 | `customer_repository_impl.dart` line 51          | Low      | ✅ Fixed | `firstWhere` throws `StateError` instead of clean exception    |
| BUG-006 | 3 files                                          | High     | ✅ Fixed | `currentUser!` force unwrap crashes on session expiry          |
| BUG-007 | `knowledge_note_repository_impl.dart` line 121   | High     | ✅ Fixed | `archiveNote` no offline guard — note reappears after sync     |
| BUG-008 | SQL RPC `batch_sync_jobs`                        | High     | ✅ Fixed | Already correct in live DB                                     |
| BUG-009 | `profile_repository_impl.dart` line 16           | Medium   | ✅ Fixed | `_authUserId` returns `''` instead of throwing                 |
| BUG-010 | `knowledge_note_repository_impl.dart` line 64    | Medium   | ✅ Fixed | No `syncPendingNotes()` — offline notes lost on remote fetch   |
| BUG-011 | `customer_repository_impl.dart` line 50          | Low      | ✅ Fixed | `getCustomerById` fetches 1000 customers to find one           |
| BUG-012 | `customer_local_datasource.dart` + notes ds      | Low      | ✅ Fixed | Missing `flush()` in customer and note datasources             |
| BUG-013 | `add_customer_screen.dart`, `add_note_screen.dart`, `edit_profile_screen.dart` | High | Open | `onChanged: setState` kills keyboard focus on 3 more screens |
| BUG-014 | `add_customer_screen.dart`, `log_job_screen.dart`, `edit_profile_screen.dart` | High | Open | Phone fields missing Ghana format + 10-digit limit             |
| BUG-015 | `job_list_screen.dart`                           | Medium   | Open     | No sync status indicator — background sync is invisible        |
| BUG-016 | All form screens                                 | Medium   | Open     | No `maxLength` — unbounded input crashes DB constraints        |
| BUG-017 | `log_job_screen.dart` amount field               | Medium   | Open     | Amount field accepts negatives and non-numeric input           |
| BUG-018 | 3 list screens (search fields)                   | Low      | Open     | Search `onChanged` calls Riverpod + `setState` redundantly     |

---

## Supabase Diagnostic Queries
Run these in the SQL Editor of your Testing or Production Supabase project to inspect live data.

```sql
-- 1. All jobs and their sync status
SELECT id, customer_id, service_type, job_date, sync_status, is_archived, created_at
FROM jobs
ORDER BY created_at DESC
LIMIT 100;

-- 2. Jobs that are NOT synced (stuck in pending or failed)
SELECT id, service_type, job_date, sync_status, created_at
FROM jobs
WHERE sync_status != 'synced'
ORDER BY created_at DESC;

-- 3. All customers and their job count
SELECT id, full_name, phone_number, total_jobs, last_job_at, created_at
FROM customers
ORDER BY last_job_at DESC NULLS LAST
LIMIT 100;

-- 4. All pending corrections
SELECT cr.id, cr.job_id, cr.reason, cr.status, cr.created_at,
       j.service_type, j.job_date
FROM correction_requests cr
JOIN jobs j ON cr.job_id = j.id
ORDER BY cr.created_at DESC;

-- 5. Follow-up status per job
SELECT j.id, j.service_type, j.job_date, j.follow_up_sent,
       f.id AS follow_up_id, f.sent_at
FROM jobs j
LEFT JOIN follow_ups f ON f.job_id = j.id
ORDER BY j.job_date DESC
LIMIT 50;

-- 6. All users and their registration status
SELECT id, auth_id, full_name, phone_number, role, status, profile_slug, created_at
FROM users
ORDER BY created_at DESC;

-- 7. Check for orphaned jobs (job customer_id not in customers table)
SELECT j.id, j.customer_id, j.service_type, j.job_date
FROM jobs j
LEFT JOIN customers c ON j.customer_id = c.id
WHERE c.id IS NULL;

-- 8. Knowledge notes with pending sync (in practice these are stuck — BUG-010)
-- knowledge_notes has no sync_status column in DB. All notes in DB are considered synced.
-- To check what's in Hive locally, filter by app logs or device inspection.
SELECT id, user_id, title, is_archived, created_at
FROM knowledge_notes
ORDER BY created_at DESC
LIMIT 50;

-- 9. Profiles summary
SELECT p.id, p.display_name, p.profile_url, p.is_public, p.whatsapp_number,
       u.full_name, u.status
FROM profiles p
JOIN users u ON u.auth_id = p.user_id
ORDER BY p.created_at DESC;

-- 10. Duplicate follow_ups check (should never happen due to UNIQUE(job_id) constraint)
SELECT job_id, COUNT(*) as count
FROM follow_ups
GROUP BY job_id
HAVING COUNT(*) > 1;
```

---

## BUG-025 — Light Mode: White Text on White/Light Backgrounds
**Severity:** High — text invisible in light mode
**Status:** ✅ FIXED (Session 28B)

### Root Cause
When the light palette was applied, `primary800` became `#FFFFFF` (white). Several widgets used hardcoded `Colors.white` or `Colors.white.withValues()` for text/icons, which rendered white-on-white and became invisible.

### Fix
Full audit of 20+ files. All hardcoded `Colors.white`, `Colors.black`, and `Colors.white.withValues()` replaced with semantic `context.ksc.*` tokens (`context.ksc.white`, `context.ksc.neutral050`, etc.).

---

## BUG-026 — Re-install: Empty Data After Fresh Login
**Severity:** High — app appears broken on first use after reinstall
**Status:** ✅ FIXED (Session 28B)

### File
`lib/features/auth/presentation/providers/auth_notifier.dart` — `verifyOtp()` method

### Root Cause
Riverpod providers (`profileProvider`, `jobListProvider`, `customerListProvider`, `notesListProvider`) retained their cached values (empty or stale) from a previous session. After a fresh reinstall and new login, the providers were never invalidated, so they returned empty data even though the user was now authenticated.

### Fix
After `authStateProvider.refresh()` in `verifyOtp()`, explicitly call `_ref.invalidate()` on all four data providers to force a fresh fetch.

---

## BUG-027 — Communication Status Section Blank (Race Condition)
**Severity:** Medium — feature invisible until user navigates away and back
**Status:** ✅ FIXED (Session 28B)

### File
`lib/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart`

### Root Cause
`EditableFollowUpProvider.initialize()` was called once in `initState` via `addPostFrameCallback`. If customer data wasn't loaded yet when that callback fired, `initialize()` would exit early and `isInitialized` would remain `false` forever. The widget returned `SizedBox.shrink()` for `!isInitialized`.

### Fix
Added retry logic in the `build()` method's `data()` callback: whenever customer data is present but `editState.isInitialized` is still false, schedule another `addPostFrameCallback` to retry initialization.

---

## BUG-028 — RenderFlex Overflow on Small Screens
**Severity:** Low — visual glitch on narrow devices
**Status:** ✅ FIXED (Session 28B)

### Files
- `lib/features/job_logging/presentation/screens/admin_requests_screen.dart`
- `lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart`

### Root Cause
`Row` with `MainAxisAlignment.spaceBetween` contained two `Text` widgets with no `Expanded` wrapper. On devices with width ≤ 270px, both texts competed for space and caused a 0.626px overflow.

### Fix
Wrapped the first `Text` in `Expanded` in both locations.

---

## BUG-029 — Discard Dialog Buttons Unstyled in Log Job Screen
**Severity:** Low — inconsistency vs other screens
**Status:** ✅ FIXED (Session 28B)

### File
`lib/features/job_logging/presentation/screens/log_job_screen.dart`

### Root Cause
The discard dialog in `log_job_screen.dart` used plain `const Text('KEEP EDITING')` and `const Text('DISCARD')` with no styling. All other discard dialogs in the app (add_customer_screen, edit_note_screen, edit_profile_screen) used `AppTextStyles.label` with semantic colors.

### Fix
Both buttons now use `AppTextStyles.label.copyWith(color: ...)` — neutral400 for "KEEP EDITING", error500 bold for "DISCARD".

---

## BUG-030 — Web Loading Screen: Brand Name Invisible (White on White)
**Severity:** Medium — brand name not visible during app load
**Status:** ✅ FIXED (Session 29)

### File
`web/index.html`

### Root Cause
When the web theme was switched to light (`#F4F7FF` background), the CSS `.brand-name` color was still `#FFFFFF` (white). The result was white text on a near-white background — completely invisible.

### Fix
- `.brand-name` color: `#FFFFFF` → `#0A1628` (dark navy, readable on light background)
- `.brand-sub` color: `#D4A853` → `#D4A017` (brighter gold for better visibility)
- Sub-label text: `PORTAL` → `FOR LOCKSMITHS` (plain English)

---

## BUG-031 — job_list_screen Build Errors: AppColors Scope + Missing ()
**Severity:** High — build failure, app would not compile
**Status:** ✅ FIXED (Session 29)

### File
`lib/features/job_logging/presentation/screens/job_list_screen.dart`

### Root Cause
Two errors introduced during light mode migration:
1. `_buildLoadingState` was referenced without parentheses — treated as a method object (`Object`), not a `Widget`.
2. `AppColors.primary800` and `AppColors.primary700` were used inside `_buildLoadingState()` — a widget method. `AppColors` is a static class only valid at theme-definition time, not accessible in widget scope.

### Fix
1. Added `()` to `_buildLoadingState()` call.
2. Replaced `AppColors.primary800/700` with `context.ksc.primary800/700`.
