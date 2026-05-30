import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/core/services/local_notification_service.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import 'package:keystone/features/recurring_jobs/domain/entities/recurring_schedule_entity.dart';
import '../../engine/reminder_engine.dart';
import '../../domain/models/reminder_model.dart';
import '../../domain/models/reminder_thresholds.dart';
import '../../data/datasources/reminder_remote_datasource.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/repositories/reminder_repository.dart';

class RemindersState {
  final List<Reminder> reminders;
  final Set<String> dismissedKeys; // "$jobId-${type.name}"

  const RemindersState({
    this.reminders = const [],
    this.dismissedKeys = const {},
  });

  List<Reminder> get active => reminders.where((r) => !r.isDismissed).toList();
  int get activeCount => active.length;
}

class RemindersNotifier extends StateNotifier<RemindersState> {
  final Ref _ref;
  static final Set<String> _notifiedKeys = {};
  static const _dismissedHiveKey = 'dismissed_reminder_keys';

  RemindersNotifier(this._ref) : super(const RemindersState()) {
    _loadDismissed();
    _compute();
  }

  void _loadDismissed() {
    try {
      final box = HiveService.reminders;
      final stored = box.get(_dismissedHiveKey);
      if (stored is List) {
        final loaded = Set<String>.from(stored);
        state = RemindersState(reminders: state.reminders, dismissedKeys: loaded);
        print('[KS:REMINDERS] Loaded ${loaded.length} dismissed keys from Hive');
      }
    } catch (e) {
      print('[KS:REMINDERS] Failed to load dismissed keys: $e');
    }
  }

  void _compute() {
    final now = DateTime.now();
    final dismissed = state.dismissedKeys;
    final t = ReminderThresholds.load();

    final jobs = _ref.read(jobListProvider).activeJobs;

    // Build follow-ups map from Hive
    final followUps = <String, Map<String, dynamic>>{};
    try {
      final box = HiveService.followUps;
      for (final key in box.keys) {
        final val = box.get(key);
        if (val is Map) {
          followUps[key.toString()] = val.cast<String, dynamic>();
        }
      }
    } catch (_) {}

    // Build recurring schedules from Hive
    final schedules = <RecurringScheduleEntity>[];
    try {
      for (final e in HiveService.recurringSchedules.values) {
        final m = e as Map;
        schedules.add(RecurringScheduleEntity(
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
        ));
      }
    } catch (_) {}

    final result = ReminderEngine.compute(
      jobs: jobs,
      followUps: followUps,
      recurringSchedules: schedules,
      thresholds: t,
      dismissedKeys: dismissed,
      now: now,
    );

    // Clean up notifiedKeys: remove keys that are no longer in newlyActive
    // so reminders can re-fire if conditions re-trigger (e.g. job re-enters
    // completed/unpaid after payment reversal).
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

  void dismiss(String jobId, ReminderType type) {
    final key = '$jobId-${type.name}';
    final newDismissed = {...state.dismissedKeys, key};
    final updated = state.reminders.map((r) {
      if (r.jobId == jobId && r.type == type) return r.copyWith(isDismissed: true);
      return r;
    }).toList();
    state = RemindersState(reminders: updated, dismissedKeys: newDismissed);

    // Also remove from notifiedKeys so it can re-fire if re-enabled
    _notifiedKeys.remove(key);

    // Persist to Hive so dismissal survives app restart
    try {
      final box = HiveService.reminders;
      box.put(_dismissedHiveKey, newDismissed.toList());
      box.flush();
    } catch (e) {
      print('[KS:REMINDERS] Failed to persist dismissed key: $e');
    }
  }

  void refresh() => _compute();
}

final reminderRemoteDatasourceProvider = Provider<ReminderRemoteDatasource>((ref) {
  return ReminderRemoteDatasource();
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(ref.watch(reminderRemoteDatasourceProvider));
});

final remindersProvider = StateNotifierProvider.autoDispose<RemindersNotifier, RemindersState>(
  (ref) {
    final notifier = RemindersNotifier(ref);
    // Recompute when job list changes
    ref.listen(jobListProvider, (_, __) => notifier.refresh());
    return notifier;
  });
