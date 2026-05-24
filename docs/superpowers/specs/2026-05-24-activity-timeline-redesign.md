# Activity Timeline — Reliability & Scope Fix

Date: 2026-05-24
Status: Approved design

## Problem

The `/activity` timeline screen fails to load in two scenarios:

1. **Bad audit entry in Hive** — `timeline_provider.dart` reads ALL entries in a single `.map()`. If one entry has null fields, missing keys, or old schema, the entire load throws → user sees "Could not load activity."

2. **Cross-provider crash** — The provider reads `jobListProvider.allJobs` to build a job-name lookup. Both providers are `autoDispose`. If the jobs provider was disposed, `_ref.read()` throws "Tried to use X after dispose."

## Scope

### P0 — Fix Load Reliability

**1. Per-entry error handling** (replace monolithic `.map()`)

```dart
// Before — whole batch fails on one bad entry
final allEntries = HiveService.jobAuditLog.values
    .map((e) => JobAuditEntryModel.fromJson(...).toEntity())
    .toList();

// After — skip bad entries, log them
final allEntries = <JobAuditEntryEntity>[];
for (final e in HiveService.jobAuditLog.values) {
  try {
    allEntries.add(JobAuditEntryModel.fromJson(Map<String, dynamic>.from(e)).toEntity());
  } catch (err) {
    debugPrint('[KS:TIMELINE] Skipping bad audit entry: $err');
  }
}
```

**2. Remove `jobListProvider` dependency** (read Hive jobs box directly)

```dart
// Before — fragile cross-provider read
final jobMap = <String, JobEntity>{
    for (final j in _ref.read(jobListProvider).allJobs) j.id: j,
};

// After — self-contained, reads from Hive directly
final jobMap = <String, JobEntity>{
    for (final j in HiveService.jobs.values)
      j.id: JobModel.fromJson(Map<String, dynamic>.from(j)).toEntity()
};
```

Requires importing `JobModel` from `job_logging/data/models/job_model.dart` and `JobEntity` from `job_logging/domain/entities/job_entity.dart`.

**3. Remove `autoDispose` from `timelineProvider`**

```dart
// Before
final timelineProvider = StateNotifierProvider.autoDispose<TimelineNotifier, TimelineState>(...);

// After
final timelineProvider = StateNotifierProvider<TimelineNotifier, TimelineState>(...);
```

Why: State persists across navigation. User returns to timeline → data is already loaded. No reload on every visit. Manual refresh button in app bar covers the need to force-refresh.

### P1 — Better Job Label Fallback

When a job referenced by an audit entry no longer exists in the jobs box, show:

> `(deleted job)`

instead of the current generic `'Job'`. Change in `_toEvent`:

```dart
final jobLabel = job?.serviceType ?? '(deleted job)';
```

### P2 — Lazy Loading & Pull-to-Refresh

**Initial load:** Show most recent 50 entries (keeps first-paint fast, same as now).

**"Load older" button:** At bottom of the event list. Tap loads the next 50 entries from the sorted full list. State tracks `_loadedCount` (starts at 50, grows by 50 on each load).

**Pull-to-refresh:** `RefreshIndicator` wrapping the `ListView`. Calls `load()` which re-reads all from Hive and resets to first 50.

**No hard cap:** Eventually loads all entries as user scrolls through history.

### P3 — Visual Polish (Quick Pass)

Match the clean display style from the template drawer redesign:
- Remove `primary800` container background on event tiles (no input-look)
- Clean rows: colored dot + text, no Card/Container box
- Typography: bump item text to 13px, labels to 10px
- No background fills on items — just the dot and text

### What Stays The Same

- Event types and their colored dots (jobCreated → success, paymentChanged → gold, etc.)
- Tapping an event navigates to job detail via `context.push(RouteNames.jobDetail(event.jobId))`
- Date grouping headers
- Constructor auto-load (`load()` called in `TimelineNotifier` constructor)
- Same file structure — only `timeline_provider.dart` and `timeline_screen.dart` change

## File Changes

| File | Changes |
|---|---|
| `timeline_provider.dart` | Per-entry try/catch, remove `jobListProvider` dep, read jobs from Hive directly, remove `autoDispose`, `(deleted job)` fallback, lazy load state (`_loadedCount`) |
| `timeline_screen.dart` | `RefreshIndicator`, "Load older" button at list bottom, visual polish (remove tile backgrounds, bump typography) |
| No new files | |

## Implementation Order

1. Provider: per-entry error handling
2. Provider: remove `jobListProvider` dep, read jobs from Hive directly
3. Provider: remove `autoDispose`
4. Provider: `(deleted job)` fallback
5. Provider + Screen: lazy load with `_loadedCount` + "Load older" button
6. Screen: `RefreshIndicator`
7. Screen: visual polish pass
8. `flutter analyze` — 0 issues
9. Hot restart on device
