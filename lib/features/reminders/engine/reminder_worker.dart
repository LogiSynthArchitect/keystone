import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/core/constants/app_enums.dart';
import 'package:keystone/features/recurring_jobs/domain/entities/recurring_schedule_entity.dart';
import '../domain/models/reminder_model.dart';
import '../domain/models/reminder_thresholds.dart';
import 'reminder_engine.dart';

const String backgroundTaskName = 'keystone_reminder_check';
const String _notifiedHiveKey = 'background_notified_keys';

/// Top-level callback registered with Workmanager.
/// Runs in a headless Dart isolate — no ProviderScope, no BuildContext.
@pragma('vm:entry-point')
void reminderBackgroundCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != backgroundTaskName) return false;
    try {
      await Hive.initFlutter();
      await _openReminderBoxes();
      await _runReminderCheck();
      return true;
    } catch (e) {
      print('[KS:WORKMANAGER] Background task failed: $e');
      return false;
    }
  });
}

Future<void> _openReminderBoxes() async {
  final boxes = [
    HiveService.jobsBox,
    HiveService.followUpsBox,
    HiveService.recurringSchedulesBox,
    HiveService.remindersBox,
    HiveService.settingsBox,
  ];
  for (final name in boxes) {
    try {
      await Hive.openBox(name);
    } catch (e) {
      // Try recovering corrupted box
      try {
        await Hive.deleteBoxFromDisk(name);
        await Hive.openBox(name);
      } catch (_) {
        print('[KS:WORKMANAGER] Could not open box $name: $e');
      }
    }
  }
}

Future<void> _runReminderCheck() async {
  final now = DateTime.now();
  final thresholds = ReminderThresholds.load();
  final dismissedBox = Hive.box(HiveService.remindersBox);
  final storedDismissed = dismissedBox.get('dismissed_reminder_keys');
  final dismissedKeys = storedDismissed is List ? Set<String>.from(storedDismissed) : <String>{};

  // Read jobs from Hive
  final jobs = _readJobsFromHive(now);

  // Read follow-ups from Hive
  final followUps = _readFollowUpsFromHive();

  // Read recurring schedules from Hive
  final schedules = _readSchedulesFromHive(now);

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
  await _fireNotifications(result.newlyActive);

  // Persist notified keys
  final notifiedKeys = result.newlyActive.map((r) => '${r.jobId}-${r.type.name}').toList();
  dismissedBox.put(_notifiedHiveKey, notifiedKeys);
  await dismissedBox.flush();
}

Future<void> _fireNotifications(List<Reminder> reminders) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await plugin.initialize(const InitializationSettings(android: android, iOS: ios));

  for (final r in reminders) {
    final title = switch (r.type) {
      ReminderType.unpaidJob => 'Unpaid Job Reminder',
      ReminderType.stuckInProgress => 'Job Stuck In Progress',
      ReminderType.followUpPending => 'Follow-up Pending',
      ReminderType.followUpNoResponse => 'No Response on Follow-up',
      ReminderType.recurringJobOverdue => 'Recurring Job Overdue',
    };

    final amount = r.amountCharged != null ? 'GHS ${(r.amountCharged! / 100).toStringAsFixed(0)}' : null;
    final body = [r.jobServiceType, if (amount != null) amount].join(' — ');

    const androidDetails = AndroidNotificationDetails(
      'keystone_reminders',
      'Job Reminders',
      channelDescription: 'Reminders for unpaid, stuck, and follow-up jobs',
      importance: Importance.high,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails());

    await plugin.show(
      r.jobId.hashCode,
      title,
      body,
      details,
      payload: r.jobId,
    );
  }
}

List<JobEntity> _readJobsFromHive(DateTime now) {
  try {
    final box = Hive.box(HiveService.jobsBox);
    return box.values
        .map((e) => _jobFromMap(e as Map<dynamic, dynamic>))
        .where((j) => j != null)
        .cast<JobEntity>()
        .toList();
  } catch (e) {
    print('[KS:WORKMANAGER] Failed to read jobs: $e');
    return [];
  }
}

Map<String, Map<String, dynamic>> _readFollowUpsFromHive() {
  try {
    final box = Hive.box(HiveService.followUpsBox);
    final map = <String, Map<String, dynamic>>{};
    for (final key in box.keys) {
      final val = box.get(key);
      if (val is Map) {
        map[key.toString()] = Map<String, dynamic>.from(val);
      }
    }
    return map;
  } catch (e) {
    print('[KS:WORKMANAGER] Failed to read follow-ups: $e');
    return {};
  }
}

List<RecurringScheduleEntity> _readSchedulesFromHive(DateTime now) {
  try {
    final box = Hive.box(HiveService.recurringSchedulesBox);
    return box.values.map((e) {
      final m = e as Map<dynamic, dynamic>;
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
  } catch (e) {
    print('[KS:WORKMANAGER] Failed to read schedules: $e');
    return [];
  }
}

JobEntity? _jobFromMap(Map<dynamic, dynamic> map) {
  try {
    final syncStatusStr = map['sync_status'] as String?;
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
        (s) => s.name == syncStatusStr,
        orElse: () => SyncStatus.synced,
      ),
      coverImageUrl: map['cover_image_url'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  } catch (e) {
    print('[KS:WORKMANAGER] Failed to parse job: $e');
    return null;
  }
}
