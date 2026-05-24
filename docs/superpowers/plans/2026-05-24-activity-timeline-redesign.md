# Activity Timeline — Reliability & Scope Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the activity timeline so it loads reliably (no crash on bad entries or disposed providers), adds pull-to-refresh, lazy loading, and clean visual design.

**Architecture:** Two files change — `timeline_provider.dart` gets per-entry error handling, self-contained job data loading (reads Hive directly instead of cross-provider), non-autoDispose lifecycle, and lazy-load state tracking. `timeline_screen.dart` gets `RefreshIndicator`, "Load older" button, and visual polish (removed tile backgrounds).

**Tech Stack:** Flutter, Riverpod, Hive

---

### Task 1: Provider — Per-Entry Error Handling

**Files:**
- Modify: `lib/features/activity_timeline/presentation/providers/timeline_provider.dart:69-91`

- [ ] **Step 1: Replace monolithic `.map()` with per-entry try/catch**

Change the `load()` method in `timeline_provider.dart`:

```dart
  Future<void> load() async {
    state = const TimelineState(isLoading: true);
    try {
      // Read all audit entries from Hive — skip bad entries instead of crashing
      final allEntries = <JobAuditEntryEntity>[];
      for (final e in HiveService.jobAuditLog.values) {
        try {
          allEntries.add(
            JobAuditEntryModel.fromJson(Map<String, dynamic>.from(e)).toEntity(),
          );
        } catch (err) {
          debugPrint('[KS:TIMELINE] Skipping bad audit entry: $err');
        }
      }

      // Build job lookup for descriptions
      final jobMap = <String, JobEntity>{
        for (final j in _ref.read(jobListProvider).allJobs) j.id: j,
      };

      // Convert audit entries to timeline events, take most recent 50
      allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recent = allEntries.take(50).toList();

      final events = recent.map((entry) => _toEvent(entry, jobMap)).toList();

      state = TimelineState(events: events);
    } catch (e) {
      state = const TimelineState(errorMessage: 'Could not load activity.');
    }
  }
```

- [ ] **Step 2: Run `flutter analyze` to verify no issues**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze lib/features/activity_timeline/presentation/providers/timeline_provider.dart`
Expected: No errors or warnings

- [ ] **Step 3: Commit**

```bash
git add lib/features/activity_timeline/presentation/providers/timeline_provider.dart
git commit -m "fix(timeline): per-entry error handling — skip bad audit entries instead of crashing whole load"
```

---

### Task 2: Provider — Remove `jobListProvider` Dependency

**Files:**
- Modify: `lib/features/activity_timeline/presentation/providers/timeline_provider.dart:1-7` (imports)
- Modify: `lib/features/activity_timeline/presentation/providers/timeline_provider.dart:69-91` (load method)

- [ ] **Step 1: Update imports**

Remove the `jobListProvider` import and `JobEntity` import if only used here. Add `JobModel` import:

```dart
// Before:
import 'package:keystone/features/job_logging/data/models/job_audit_entry_model.dart';
import 'package:keystone/features/job_logging/domain/entities/job_audit_entry_entity.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';

// After:
import 'package:keystone/features/job_logging/data/models/job_audit_entry_model.dart';
import 'package:keystone/features/job_logging/domain/entities/job_audit_entry_entity.dart';
import 'package:keystone/features/job_logging/data/models/job_model.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
```

- [ ] **Step 2: Replace `_ref.read(jobListProvider)` with direct Hive read**

Change the job map construction inside `load()`:

```dart
      // Before:
      final jobMap = <String, JobEntity>{
        for (final j in _ref.read(jobListProvider).allJobs) j.id: j,
      };

      // After:
      final jobMap = <String, JobEntity>{
        for (final j in HiveService.jobs.values)
          j.id: JobModel.fromJson(Map<String, dynamic>.from(j)).toEntity()
      };
```

- [ ] **Step 3: Run `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze lib/features/activity_timeline/presentation/providers/timeline_provider.dart`
Expected: No errors or warnings

- [ ] **Step 4: Commit**

```bash
git add lib/features/activity_timeline/presentation/providers/timeline_provider.dart
git commit -m "fix(timeline): read jobs from Hive directly — remove cross-provider crash from autoDispose"
```

---

### Task 3: Provider — Remove `autoDispose`

**Files:**
- Modify: `lib/features/activity_timeline/presentation/providers/timeline_provider.dart:150`

- [ ] **Step 1: Remove `.autoDispose` from provider declaration**

```dart
// Before:
final timelineProvider = StateNotifierProvider.autoDispose<TimelineNotifier, TimelineState>(
  (ref) => TimelineNotifier(ref));

// After:
final timelineProvider = StateNotifierProvider<TimelineNotifier, TimelineState>(
  (ref) => TimelineNotifier(ref));
```

- [ ] **Step 2: Run `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze lib/features/activity_timeline/presentation/providers/timeline_provider.dart`
Expected: No errors or warnings

- [ ] **Step 3: Commit**

```bash
git add lib/features/activity_timeline/presentation/providers/timeline_provider.dart
git commit -m "fix(timeline): remove autoDispose — state persists across navigation, instant content on return"
```

---

### Task 4: Provider — Better Deleted Job Fallback

**Files:**
- Modify: `lib/features/activity_timeline/presentation/providers/timeline_provider.dart:95`

- [ ] **Step 1: Change the job label fallback**

```dart
// Before:
final jobLabel = job?.serviceType ?? 'Job';

// After:
final jobLabel = job?.serviceType ?? '(deleted job)';
```

- [ ] **Step 2: Run `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze lib/features/activity_timeline/presentation/providers/timeline_provider.dart`
Expected: No errors or warnings

- [ ] **Step 3: Commit**

```bash
git add lib/features/activity_timeline/presentation/providers/timeline_provider.dart
git commit -m "fix(timeline): show '(deleted job)' instead of generic 'Job' when job no longer exists"
```

---

### Task 5: Provider + Screen — Lazy Loading with "Load Older"

**Files:**
- Modify: `lib/features/activity_timeline/presentation/providers/timeline_provider.dart`
- Modify: `lib/features/activity_timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Add `_loadedCount` state tracking to `TimelineState` and `TimelineNotifier`**

In `timeline_provider.dart`, add `loadedCount` to `TimelineState`:

```dart
class TimelineState {
  final List<TimelineEvent> events;
  final bool isLoading;
  final String? errorMessage;
  final int loadedCount; // how many entries loaded so far
  final int totalCount;  // total available entries

  const TimelineState({
    this.events = const [],
    this.isLoading = false,
    this.errorMessage,
    this.loadedCount = 0,
    this.totalCount = 0,
  });
}
```

- [ ] **Step 2: Update `load()` to track total count and initial 50**

```dart
  Future<void> load() async {
    state = const TimelineState(isLoading: true);
    try {
      // Read all audit entries from Hive — skip bad entries instead of crashing
      final allEntries = <JobAuditEntryEntity>[];
      for (final e in HiveService.jobAuditLog.values) {
        try {
          allEntries.add(
            JobAuditEntryModel.fromJson(Map<String, dynamic>.from(e)).toEntity(),
          );
        } catch (err) {
          debugPrint('[KS:TIMELINE] Skipping bad audit entry: $err');
        }
      }

      // Build job lookup for descriptions
      final jobMap = <String, JobEntity>{
        for (final j in HiveService.jobs.values)
          j.id: JobModel.fromJson(Map<String, dynamic>.from(j)).toEntity()
      };

      // Sort all by time, newest first
      allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final total = allEntries.length;
      final initialCount = total > 50 ? 50 : total;

      final events = allEntries.take(initialCount).map((entry) => _toEvent(entry, jobMap)).toList();

      state = TimelineState(events: events, loadedCount: initialCount, totalCount: total);
    } catch (e) {
      state = const TimelineState(errorMessage: 'Could not load activity.');
    }
  }
```

- [ ] **Step 3: Add `loadMore()` method to `TimelineNotifier`**

After the `load()` method, add:

```dart
  Future<void> loadMore() async {
    if (state.loadedCount >= state.totalCount) return;
    try {
      final allEntries = <JobAuditEntryEntity>[];
      for (final e in HiveService.jobAuditLog.values) {
        try {
          allEntries.add(
            JobAuditEntryModel.fromJson(Map<String, dynamic>.from(e)).toEntity(),
          );
        } catch (err) {
          debugPrint('[KS:TIMELINE] Skipping bad audit entry: $err');
        }
      }

      final jobMap = <String, JobEntity>{
        for (final j in HiveService.jobs.values)
          j.id: JobModel.fromJson(Map<String, dynamic>.from(j)).toEntity()
      };

      allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final newCount = state.loadedCount + 50 > state.totalCount
          ? state.totalCount
          : state.loadedCount + 50;

      final events = allEntries.take(newCount).map((entry) => _toEvent(entry, jobMap)).toList();

      state = TimelineState(events: events, loadedCount: newCount, totalCount: state.totalCount);
    } catch (e) {
      // Silently fail — user can tap again
      debugPrint('[KS:TIMELINE] loadMore failed: $e');
    }
  }
```

- [ ] **Step 4: Add "Load older" button to screen**

In `timeline_screen.dart`, modify the `_EventList` to show a load-more button when there are more entries:

```dart
class _EventList extends StatelessWidget {
  final List<TimelineEvent> events;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  const _EventList({required this.events, this.hasMore = false, this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge),
      itemCount: events.length + (hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == events.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: TextButton.icon(
                onPressed: onLoadMore,
                icon: Icon(LineAwesomeIcons.angle_double_down_solid, size: 14, color: context.ksc.accent500),
                label: Text('LOAD OLDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ksc.accent500, letterSpacing: 1)),
              ),
            ),
          );
        }
        final event = events[i];
        final showDate = i == 0 || !_sameDay(events[i - 1].timestamp, event.timestamp);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate) _DateLabel(event.timestamp),
            _EventTile(event: event),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
```

- [ ] **Step 5: Pass `hasMore` and `onLoadMore` from screen**

Update the screen's `build()` method where `_EventList` is used:

```dart
              : state.events.isEmpty
                  ? _EmptyState()
                  : _EventList(
                      events: state.events,
                      hasMore: state.loadedCount < state.totalCount,
                      onLoadMore: () => ref.read(timelineProvider.notifier).loadMore(),
                    ),
```

- [ ] **Step 6: Run `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze lib/features/activity_timeline/`
Expected: No errors or warnings

- [ ] **Step 7: Commit**

```bash
git add lib/features/activity_timeline/presentation/providers/timeline_provider.dart lib/features/activity_timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): lazy loading with 'Load older' button — shows first 50, loads more on tap"
```

---

### Task 6: Screen — Pull-to-Refresh

**Files:**
- Modify: `lib/features/activity_timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Wrap the event list in `RefreshIndicator`**

In `timeline_screen.dart`, wrap the content that shows events with a `RefreshIndicator`:

```dart
  body: state.isLoading
      ? const Center(child: KsLoadingIndicator())
      : state.errorMessage != null
          ? Center(child: Text(state.errorMessage!, style: AppTextStyles.body.copyWith(color: context.ksc.error500)))
          : state.events.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref.read(timelineProvider.notifier).load(),
                  child: _EventList(
                    events: state.events,
                    hasMore: state.loadedCount < state.totalCount,
                    onLoadMore: () => ref.read(timelineProvider.notifier).loadMore(),
                  ),
                ),
```

- [ ] **Step 2: Run `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze lib/features/activity_timeline/presentation/screens/timeline_screen.dart`
Expected: No errors or warnings

- [ ] **Step 3: Commit**

```bash
git add lib/features/activity_timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): pull-to-refresh — pull down to reload all entries"
```

---

### Task 7: Screen — Visual Polish

**Files:**
- Modify: `lib/features/activity_timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Remove `primary800` container background from `_EventTile`**

Replace the `_EventTile.build()` method to remove the container background and use clean rows:

```dart
  @override
  Widget build(BuildContext context) {
    final dot = _dotColor(context);

    return GestureDetector(
      onTap: () => context.push(RouteNames.jobDetail(event.jobId)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Container(
                        width: 1,
                        color: context.ksc.primary700.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Content — no background container
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.type.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: dot,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Text(
                            _timeString(event.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: context.ksc.neutral600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.ksc.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

Note: This changes the layout from a filled card (icon + text inside a `primary800` box) to a clean timeline style: a colored dot + vertical line on the left, event type + description + time on the right with no background fill.

- [ ] **Step 2: Run `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze lib/features/activity_timeline/presentation/screens/timeline_screen.dart`
Expected: No errors or warnings

- [ ] **Step 3: Commit**

```bash
git add lib/features/activity_timeline/presentation/screens/timeline_screen.dart
git commit -m "refactor(timeline): clean visual design — removed tile backgrounds, added timeline connector line, bumped typography"
```

---

### Task 8: Final Verification

- [ ] **Step 1: Run full `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze lib/features/activity_timeline/`
Expected: No issues found

- [ ] **Step 2: Push commit**

```bash
git push
```

- [ ] **Step 3: Hot restart on device**

Send `R` to the running `flutter run` PTY session.
