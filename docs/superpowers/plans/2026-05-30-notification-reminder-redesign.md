# Notification & Reminder System Redesign

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Production-ready background reminder system with Supabase persistence, notification tap navigation, and all 9 identified gaps fixed.

**Architecture:** Extract standalone `ReminderEngine` from the current `RemindersNotifier`, implement the 5 stubbed `ReminderRepository` methods against Supabase, add `workmanager` for periodic background execution, and fix all known bugs (notification tap, RESEND, notifiedKeys leak, threshold save refresh).

**Tech Stack:** Flutter 3.3+, Riverpod, Supabase, Hive, `flutter_local_notifications`, `workmanager`

---

### Task 1: Create ReminderEngine (standalone computation class)

**Files:**
- Create: `lib/features/reminders/engine/reminder_engine.dart`
- Modify: `lib/features/reminders/presentation/providers/reminders_provider.dart`

- [ ] **Step 1: Create `engine/` directory and `reminder_engine.dart`**

```dart
// lib/features/reminders/engine/reminder_engine.dart
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/recurring_jobs/domain/entities/recurring_schedule_entity.dart';
import '../domain/models/reminder_model.dart';
import '../domain/models/reminder_thresholds.dart';

class ReminderEngineResult {
  final List<Reminder> reminders;
  final List<Reminder> newlyActive;

  const ReminderEngineResult({
    required this.reminders,
    required this.newlyActive,
  });
}

/// Pure computation engine — takes data in, returns reminders out.
/// No providers, no BuildContext, no side effects.
/// Callable from both in-app (RemindersNotifier) and background (workmanager).
class ReminderEngine {
  static ReminderEngineResult compute({
    required List<JobEntity> jobs,
    required Map<String, Map<String, dynamic>> followUps,
    required List<RecurringScheduleEntity> recurringSchedules,
    required ReminderThresholds thresholds,
    required Set<String> dismissedKeys,
    required DateTime now,
  }) {
    final reminders = <Reminder>[];
    final newlyActive = <Reminder>[];

    for (final job in jobs) {
      if (job.isDeleted || job.isArchived) continue;
      final daysSince = now.difference(job.jobDate).inDays;

      if (job.status == 'completed' && job.paymentStatus == 'unpaid' && daysSince >= thresholds.unpaidJobDays) {
        _addReminder(reminders, newlyActive, job, ReminderType.unpaidJob, dismissedKeys);
      }

      if (job.status == 'in_progress' && daysSince >= thresholds.stuckInProgressDays) {
        _addReminder(reminders, newlyActive, job, ReminderType.stuckInProgress, dismissedKeys);
      }

      if (job.status == 'completed' && !job.followUpSent && daysSince >= thresholds.followUpPendingDays) {
        _addReminder(reminders, newlyActive, job, ReminderType.followUpPending, dismissedKeys);
      }

      final followUpData = followUps[job.id];
      if (followUpData != null) {
        final responseStatus = followUpData['response_status'] as String? ?? 'sent';
        final sentAtRaw = followUpData['sent_at'] as String?;

        if (responseStatus == 'no_response') {
          _addReminder(reminders, newlyActive, job, ReminderType.followUpNoResponse, dismissedKeys);
        }

        if (responseStatus == 'sent' && sentAtRaw != null) {
          final sentAt = DateTime.tryParse(sentAtRaw);
          if (sentAt != null && now.difference(sentAt).inDays >= thresholds.followUpNoResponseDays) {
            _addReminder(reminders, newlyActive, job, ReminderType.followUpNoResponse, dismissedKeys);
          }
        }
      }
    }

    for (final schedule in recurringSchedules) {
      if (!schedule.isActive || !schedule.isDue) continue;
      final daysOverdue = now.difference(schedule.nextDueDate).inDays;
      if (daysOverdue >= thresholds.recurringJobOverdueDays) {
        final key = '${schedule.id}-${ReminderType.recurringJobOverdue.name}';
        reminders.add(Reminder(
          jobId: schedule.id,
          jobServiceType: schedule.serviceType,
          jobDate: schedule.nextDueDate,
          type: ReminderType.recurringJobOverdue,
          isDismissed: dismissedKeys.contains(key),
        ));
        if (!dismissedKeys.contains(key)) {
          newlyActive.add(Reminder(
            jobId: schedule.id,
            jobServiceType: schedule.serviceType,
            jobDate: schedule.nextDueDate,
            type: ReminderType.recurringJobOverdue,
          ));
        }
      }
    }

    reminders.sort((a, b) {
      if (a.isDismissed != b.isDismissed) return a.isDismissed ? 1 : -1;
      return b.jobDate.compareTo(a.jobDate);
    });

    return ReminderEngineResult(reminders: reminders, newlyActive: newlyActive);
  }

  static void _addReminder(
    List<Reminder> reminders,
    List<Reminder> newlyActive,
    JobEntity job,
    ReminderType type,
    Set<String> dismissedKeys,
  ) {
    final key = '${job.id}-${type.name}';
    reminders.add(Reminder(
      jobId: job.id,
      jobServiceType: job.serviceType,
      jobDate: job.jobDate,
      type: type,
      amountCharged: job.amountCharged,
      isDismissed: dismissedKeys.contains(key),
    ));
    if (!dismissedKeys.contains(key)) {
      newlyActive.add(Reminder(
        jobId: job.id,
        jobServiceType: job.serviceType,
        jobDate: job.jobDate,
        type: type,
        amountCharged: job.amountCharged,
      ));
    }
  }
}
```

- [ ] **Step 2: Refactor `RemindersNotifier._compute()` to delegate to engine**

In `lib/features/reminders/presentation/providers/reminders_provider.dart`, replace the entire `_compute()` method body with:

```dart
  void _compute() {
    final now = DateTime.now();
    final dismissed = state.dismissedKeys;
    final t = ReminderThresholds.load();

    final jobs = _ref.read(jobListProvider).activeJobs;
    final followUps = _buildFollowUpMap();
    final schedules = _buildRecurringSchedules(now);

    final result = ReminderEngine.compute(
      jobs: jobs,
      followUps: followUps,
      recurringSchedules: schedules,
      thresholds: t,
      dismissedKeys: dismissed,
      now: now,
    );

    // Clean up notifiedKeys — remove stale keys so reminders can re-fire
    final newlyActiveKeys = result.newlyActive.map((r) => '${r.jobId}-${r.type.name}').toSet();
    _notifiedKeys.removeWhere((k) => !newlyActiveKeys.contains(k));

    state = RemindersState(reminders: result.reminders, dismissedKeys: dismissed);

    for (final r in result.newlyActive) {
      final key = '${r.jobId}-${r.type.name}';
      if (_notifiedKeys.add(key)) {
        LocalNotificationService.showReminderNotification(r);
      }
    }
  }

  Map<String, Map<String, dynamic>> _buildFollowUpMap() {
    try {
      final box = HiveService.followUps;
      final map = <String, Map<String, dynamic>>{};
      for (final key in box.keys) {
        final val = box.get(key);
        if (val is Map) {
          map[key.toString()] = val.cast<String, dynamic>();
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  List<RecurringScheduleEntity> _buildRecurringSchedules(DateTime now) {
    try {
      return HiveService.recurringSchedules.values.map((e) {
        return RecurringScheduleEntity(
          id: e['id'] as String? ?? '',
          userId: e['user_id'] as String? ?? '',
          customerId: e['customer_id'] as String? ?? '',
          customerName: e['customer_name'] as String? ?? '',
          serviceType: e['service_type'] as String? ?? '',
          intervalType: e['interval_type'] as String? ?? '',
          nextDueDate: DateTime.tryParse(e['next_due_date'] as String? ?? '') ?? now,
          isActive: e['is_active'] as bool? ?? true,
          notes: e['notes'] as String?,
          createdAt: DateTime.tryParse(e['created_at'] as String? ?? '') ?? now,
          updatedAt: DateTime.tryParse(e['updated_at'] as String? ?? '') ?? now,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
```

Also add the import at the top:
```dart
import 'package:keystone/features/reminders/engine/reminder_engine.dart';
```

- [ ] **Step 3: Run `flutter analyze`**

Run: `cd /home/cybocrime/workspace/projects/keystone && flutter analyze --no-fatal-infos --no-fatal-warnings`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd /home/cybocrime/workspace/projects/keystone && git add lib/features/reminders/engine/ lib/features/reminders/presentation/providers/reminders_provider.dart && git commit -m "feat(reminders): extract ReminderEngine, fix _notifiedKeys leak"
```

---

### Task 2: Implement ReminderRepositoryImpl against Supabase

**Files:**
- Create: `lib/features/reminders/data/datasources/reminder_remote_datasource.dart`
- Modify: `lib/features/reminders/data/repositories/reminder_repository_impl.dart`
- Modify: `lib/features/reminders/presentation/providers/reminders_provider.dart`

- [ ] **Step 1: Create `ReminderRemoteDatasource`**

```dart
// lib/features/reminders/data/datasources/reminder_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderRemoteDatasource {
  final SupabaseClient _client;
  ReminderRemoteDatasource(this._client);

  Future<List<Map<String, dynamic>>> getReminders(String userId) async {
    return await _client
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> createReminder(Map<String, dynamic> data) async {
    await _client.from('reminders').insert(data);
  }

  Future<void> dismissReminder(String reminderId) async {
    await _client
        .from('reminders')
        .update({'status': 'dismissed', 'dismissed_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', reminderId);
  }

  Future<void> snoozeReminder(String reminderId, String snoozedUntil) async {
    await _client
        .from('reminders')
        .update({'status': 'snoozed', 'snoozed_until': snoozedUntil})
        .eq('id', reminderId);
  }

  Future<void> resolveReminder(String reminderId) async {
    await _client
        .from('reminders')
        .update({'status': 'resolved'})
        .eq('id', reminderId);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _client.from('reminders').delete().eq('id', reminderId);
  }
}
```

- [ ] **Step 2: Implement `ReminderRepositoryImpl`**

Replace the file at `lib/features/reminders/data/repositories/reminder_repository_impl.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/reminder_entity.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_datasource.dart';
import '../models/reminder_model.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDatasource _remote;
  final SupabaseClient _supabase;

  ReminderRepositoryImpl(this._remote, this._supabase);

  String get _userId => _supabase.auth.currentUser?.id ?? '';

  @override
  Future<List<ReminderEntity>> getReminders(String userId) async {
    try {
      final data = await _remote.getReminders(userId);
      return data.map((json) => ReminderModel.fromJson(json)).toList();
    } catch (e) {
      print('[KS:REMINDERS] Failed to fetch reminders from Supabase: $e');
      return [];
    }
  }

  @override
  Future<void> createReminder(ReminderEntity reminder) async {
    try {
      await _remote.createReminder({
        'user_id': _userId,
        'job_id': reminder.jobId,
        'type': reminder.type,
        'status': reminder.status,
      });
    } catch (e) {
      print('[KS:REMINDERS] Failed to create reminder: $e');
    }
  }

  @override
  Future<void> dismissReminder(String reminderId) async {
    try {
      await _remote.dismissReminder(reminderId);
    } catch (e) {
      print('[KS:REMINDERS] Failed to dismiss reminder: $e');
    }
  }

  @override
  Future<void> snoozeReminder(String reminderId, Duration duration) async {
    try {
      final until = DateTime.now().add(duration).toUtc().toIso8601String();
      await _remote.snoozeReminder(reminderId, until);
    } catch (e) {
      print('[KS:REMINDERS] Failed to snooze reminder: $e');
    }
  }

  @override
  Future<void> resolveReminder(String reminderId) async {
    try {
      await _remote.resolveReminder(reminderId);
    } catch (e) {
      print('[KS:REMINDERS] Failed to resolve reminder: $e');
    }
  }
}
```

- [ ] **Step 3: Add providers for datasource and repository**

In `lib/features/reminders/presentation/providers/reminders_provider.dart`, add after existing imports:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/reminder_remote_datasource.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/repositories/reminder_repository.dart';
```

Add before `remindersProvider`:
```dart
final reminderRemoteDatasourceProvider = Provider<ReminderRemoteDatasource>((ref) {
  return ReminderRemoteDatasource(Supabase.instance.client);
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(
    ref.watch(reminderRemoteDatasourceProvider),
    Supabase.instance.client,
  );
});
```

- [ ] **Step 4: Run `flutter analyze`**

Run: `cd /home/cybocrime/workspace/projects/keystone && flutter analyze --no-fatal-infos --no-fatal-warnings`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
cd /home/cybocrime/workspace/projects/keystone && git add lib/features/reminders/data/ lib/features/reminders/presentation/providers/reminders_provider.dart && git commit -m "feat(reminders): implement Supabase persistence for reminders"
```

---

### Task 3: Fix notification tap handler

**Files:**
- Modify: `lib/core/services/local_notification_service.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add pending payload + callback to LocalNotificationService**

In `lib/core/services/local_notification_service.dart`, add:

```dart
  static String? _pendingJobId;
  static void Function(String jobId)? _internalTapCallback;

  /// Set from within ProviderScope to get GoRouter access.
  static set onNotificationTap(void Function(String jobId) cb) {
    _internalTapCallback = cb;
    // Fire any pending tap that happened before the callback was registered
    if (_pendingJobId != null && _pendingJobId!.isNotEmpty) {
      cb(_pendingJobId!);
      _pendingJobId = null;
    }
  }
```

Modify the `initialize` method's `onDidReceiveNotificationResponse` callback:
```dart
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          if (_internalTapCallback != null) {
            _internalTapCallback!(payload);
          } else {
            _pendingJobId = payload;
          }
        }
      },
    );
```

- [ ] **Step 2: Change `KeystoneApp` to `ConsumerStatefulWidget` and wire tap**

Replace `lib/main.dart`:

Find `class KeystoneApp extends ConsumerWidget` and change to `ConsumerStatefulWidget`:

```dart
class KeystoneApp extends ConsumerStatefulWidget {
  const KeystoneApp({super.key});
  @override
  ConsumerState<KeystoneApp> createState() => _KeystoneAppState();
}

class _KeystoneAppState extends ConsumerState<KeystoneApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      LocalNotificationService.onNotificationTap = (jobId) {
        router.push('/jobs/$jobId');
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(appThemeNotifierProvider);
    // ... rest is the same as current build ...
  }
}
```

- [ ] **Step 3: Run `flutter analyze`**

Run: `cd /home/cybocrime/workspace/projects/keystone && flutter analyze --no-fatal-infos --no-fatal-warnings`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd /home/cybocrime/workspace/projects/keystone && git add lib/core/services/local_notification_service.dart lib/main.dart && git commit -m "fix(notifications): wire notification tap to navigate to job detail"
```

---

### Task 4: Wire RESEND button on reminder card

**Files:**
- Modify: `lib/core/widgets/ks_reminder_card.dart`
- Modify: `lib/features/reminders/presentation/screens/reminders_screen.dart`

- [ ] **Step 1: Pass through `onResend` from screen to card**

In `lib/features/reminders/presentation/screens/reminders_screen.dart`, replace `onResend: () {}` with actual WhatsApp navigation.

Find the `showResend` function parameter in `_buildSection`:
```dart
    showResend: (r) => r.type == ReminderType.followUpNoResponse,
```

And the `onResend` on the card:
```dart
    onResend: showResend?.call(r) == true ? () {} : null,
```

Replace with:
```dart
    onResend: showResend?.call(r) == true ? () {
      // Navigate to the job detail screen where WhatsApp send is available
      context.push(RouteNames.jobDetail(r.jobId));
    } : null,
```

Add import:
```dart
import '../../../../core/router/route_names.dart';
```

- [ ] **Step 2: Run `flutter analyze`**

Run: `cd /home/cybocrime/workspace/projects/keystone && flutter analyze --no-fatal-infos --no-fatal-warnings`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /home/cybocrime/workspace/projects/keystone && git add lib/features/reminders/presentation/screens/reminders_screen.dart && git commit -m "fix(reminders): wire RESEND button to navigate to job detail"
```

---

### Task 5: Fix threshold save → trigger refresh

**Files:**
- Modify: `lib/features/reminders/presentation/screens/reminder_settings_screen.dart`

- [ ] **Step 1: Add refresh call after save**

In `lib/features/reminders/presentation/screens/reminder_settings_screen.dart`, find the save button's `onTap` handler.

Current:
```dart
onTap: () async {
  await ReminderThresholds.save(ReminderThresholds(...));
  if (mounted) KsSlidingNotification.show(context, message: "Reminder thresholds saved", type: KsNotificationType.success);
},
```

Add `ref` access by using `ConsumerStatefulWidget` (already is one), and add:
```dart
onTap: () async {
  await ReminderThresholds.save(ReminderThresholds(...));
  if (mounted) {
    // Trigger reminder recomputation with new thresholds
    ref.invalidate(remindersProvider);
    KsSlidingNotification.show(context, message: "Reminder thresholds saved", type: KsNotificationType.success);
  }
},
```

Add import if not present:
```dart
import '../providers/reminders_provider.dart';
```

- [ ] **Step 2: Run `flutter analyze`**

Run: `cd /home/cybocrime/workspace/projects/keystone && flutter analyze --no-fatal-infos --no-fatal-warnings`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /home/cybocrime/workspace/projects/keystone && git add lib/features/reminders/presentation/screens/reminder_settings_screen.dart && git commit -m "fix(reminders): trigger reminder recomputation on threshold save"
```

---

### Task 6: Add workmanager for background reminder execution

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/reminders/engine/reminder_worker.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add workmanager to pubspec.yaml**

Add before `flutter_local_notifications`:
```yaml
  workmanager: ^0.5.2
```

Run: `cd /home/cybocrime/workspace/projects/keystone && flutter pub get`
Expected: Package installed successfully.

- [ ] **Step 2: Create `ReminderWorker`**

```dart
// lib/features/reminders/engine/reminder_worker.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/recurring_jobs/domain/entities/recurring_schedule_entity.dart';
import '../domain/models/reminder_model.dart';
import '../domain/models/reminder_thresholds.dart';
import 'reminder_engine.dart';

const String backgroundTaskName = 'keystone_reminder_check';

/// Called from workmanager's top-level callback dispatcher.
/// This runs in a headless Dart isolate — NO ProviderScope, NO BuildContext.
@pragma('vm:entry-point')
void reminderBackgroundCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != backgroundTaskName) return false;
    try {
      // Hive must be initialized in the isolate
      await Hive.initFlutter(HiveService.getHivePath());
      await HiveService._openOnlyBoxes([
        HiveService.jobsBox,
        HiveService.followUpsBox,
        HiveService.recurringSchedulesBox,
        HiveService.remindersBox,
        HiveService.settingsBox,
      ]);

      await _runReminderCheck();
      return true;
    } catch (e) {
      print('[KS:WORKMANAGER] Background task failed: $e');
      return false;
    }
  });
}

Future<void> _runReminderCheck() async {
  final now = DateTime.now();
  final thresholds = ReminderThresholds.load();

  // Load dismissed keys
  final dismissedBox = HiveService.reminders;
  final stored = dismissedBox.get('dismissed_reminder_keys');
  final dismissedKeys = stored is List ? Set<String>.from(stored) : <String>{};

  // Load jobs from Hive
  final jobsBox = HiveService.jobs;
  final jobs = jobsBox.values
      .map((e) => _jobFromMap(e as Map))
      .where((j) => j != null)
      .cast<JobEntity>()
      .toList();

  // Load follow-ups from Hive
  final followUpsBox = HiveService.followUps;
  final followUps = <String, Map<String, dynamic>>{};
  for (final key in followUpsBox.keys) {
    final val = followUpsBox.get(key);
    if (val is Map) {
      followUps[key.toString()] = val.cast<String, dynamic>();
    }
  }

  // Load recurring schedules from Hive
  final schedulesBox = HiveService.recurringSchedules;
  final schedules = schedulesBox.values.map((e) {
    final m = e as Map;
    return RecurringScheduleEntity(
      id: m['id'] as String? ?? '',
      userId: m['user_id'] as String? ?? '',
      customerId: m['customer_id'] as String? ?? '',
      customerName: m['customer_name'] as String? ?? '',
      serviceType: m['service_type'] as String? ?? '',
      intervalType: m['interval_type'] as String? ?? '',
      nextDueDate: DateTime.tryParse(m['next_due_date'] as String? ?? '') ?? now,
      isActive: m['is_active'] as bool? ?? true,
      notes: m['notes'] as String?,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? '') ?? now,
    );
  }).toList();

  // Compute reminders
  final result = ReminderEngine.compute(
    jobs: jobs,
    followUps: followUps,
    recurringSchedules: schedules,
    thresholds: thresholds,
    dismissedKeys: dismissedKeys,
    now: now,
  );

  // Fire local notifications for newly active reminders
  final notifiedBox = HiveService.reminders;
  final notifiedKey = 'background_notified_keys';
  final storedNotified = notifiedBox.get(notifiedKey);
  final notifiedKeys = storedNotified is List ? Set<String>.from(storedNotified) : <String>{};

  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await plugin.initialize(const InitializationSettings(android: android, iOS: ios));

  for (final r in result.newlyActive) {
    final key = '${r.jobId}-${r.type.name}';
    if (notifiedKeys.add(key)) {
      final title = _notificationTitle(r.type);
      final body = _notificationBody(r);
      const androidDetails = AndroidNotificationDetails(
        'keystone_reminders',
        'Job Reminders',
        channelDescription: 'Reminders for unpaid, stuck, and follow-up jobs',
        importance: Importance.high,
        priority: Priority.high,
      );
      await plugin.show(
        r.jobId.hashCode,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
        payload: r.jobId,
      );
    }
  }

  // Persist notified keys
  notifiedBox.put(notifiedKey, notifiedKeys.toList());
  await notifiedBox.flush();
}

JobEntity? _jobFromMap(Map map) {
  try {
    return JobEntity(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      serviceType: map['service_type'] as String? ?? '',
      jobDate: DateTime.tryParse(map['job_date'] as String? ?? '') ?? DateTime.now(),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      amountCharged: map['amount_charged'] as int?,
      status: map['status'] as String? ?? 'in_progress',
      paymentStatus: map['payment_status'] as String? ?? 'unpaid',
      followUpSent: map['follow_up_sent'] as bool? ?? false,
      followUpSentAt: map['follow_up_sent_at'] != null ? DateTime.tryParse(map['follow_up_sent_at'] as String) : null,
      isArchived: map['is_archived'] as bool? ?? false,
      isDeleted: map['is_deleted'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      syncStatus: SyncStatus.values.firstWhere(
        (s) => s.name == map['sync_status'],
        orElse: () => SyncStatus.synced,
      ),
      coverImageUrl: map['cover_image_url'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  } catch (_) {
    return null;
  }
}

String _notificationTitle(ReminderType type) {
  switch (type) {
    case ReminderType.unpaidJob: return 'Unpaid Job Reminder';
    case ReminderType.stuckInProgress: return 'Job Stuck In Progress';
    case ReminderType.followUpPending: return 'Follow-up Pending';
    case ReminderType.followUpNoResponse: return 'No Response on Follow-up';
    case ReminderType.recurringJobOverdue: return 'Recurring Job Overdue';
  }
}

String _notificationBody(Reminder reminder) {
  final amount = reminder.amountCharged != null ? 'GHS ${(reminder.amountCharged! / 100).toStringAsFixed(0)}' : null;
  final parts = [reminder.jobServiceType, if (amount != null) amount];
  return parts.join(' — ');
}
```

Wait, this has an issue. The `_openOnlyBoxes` method doesn't exist on HiveService. Let me instead just use `Hive.openBox` directly in the worker, or add a helper method.

Actually, let me simplify the worker. The background task should be as lightweight as possible. Since Hive boxes are already stored on disk, in the workmanager isolate we can just open them directly:

```dart
Future<Box> _openBox(String name) async {
  return await Hive.openBox(name, path: HiveService.getHivePath());
}
```

But HiveService.getHivePath() doesn't exist either. Let me check... Actually let me just use the Hive default path which is set by `Hive.initFlutter()` in the main isolate.

In the workmanager isolate, we call `Hive.initFlutter()` which sets up the path. Then we can open boxes with just their name.

Let me simplify the worker significantly.<｜end▁of▁thinking｜>

<｜｜DSML｜｜tool_calls>
<｜｜DSML｜｜invoke name="grep">
<｜｜DSML｜｜parameter name="pattern" string="true">HiveService.getHivePath\|HiveService\._