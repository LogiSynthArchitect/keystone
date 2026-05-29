import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/core/services/local_notification_service.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import 'package:keystone/features/recurring_jobs/domain/entities/recurring_schedule_entity.dart';
import '../../domain/models/reminder_model.dart';
import '../../domain/models/reminder_thresholds.dart';

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
    final jobs = _ref.read(jobListProvider).activeJobs;
    final now = DateTime.now();
    final dismissed = state.dismissedKeys;
    final reminders = <Reminder>[];
    final newlyActive = <Reminder>[];
    final followUpsBox = HiveService.followUps;
    final t = ReminderThresholds.load();

    for (final job in jobs) {
      final daysSince = now.difference(job.jobDate).inDays;

      if (job.status == 'completed' && job.paymentStatus == 'unpaid' && daysSince >= t.unpaidJobDays) {
        final key = '${job.id}-${ReminderType.unpaidJob.name}';
        final reminder = Reminder(
          jobId: job.id,
          jobServiceType: job.serviceType,
          jobDate: job.jobDate,
          type: ReminderType.unpaidJob,
          amountCharged: job.amountCharged,
          isDismissed: dismissed.contains(key),
        );
        reminders.add(reminder);
        if (!dismissed.contains(key)) newlyActive.add(reminder);
      }

      if (job.status == 'in_progress' && daysSince >= t.stuckInProgressDays) {
        final key = '${job.id}-${ReminderType.stuckInProgress.name}';
        final reminder = Reminder(
          jobId: job.id,
          jobServiceType: job.serviceType,
          jobDate: job.jobDate,
          type: ReminderType.stuckInProgress,
          amountCharged: job.amountCharged,
          isDismissed: dismissed.contains(key),
        );
        reminders.add(reminder);
        if (!dismissed.contains(key)) newlyActive.add(reminder);
      }

      if (job.status == 'completed' && !job.followUpSent && daysSince >= t.followUpPendingDays) {
        final key = '${job.id}-${ReminderType.followUpPending.name}';
        final reminder = Reminder(
          jobId: job.id,
          jobServiceType: job.serviceType,
          jobDate: job.jobDate,
          type: ReminderType.followUpPending,
          amountCharged: job.amountCharged,
          isDismissed: dismissed.contains(key),
        );
        reminders.add(reminder);
        if (!dismissed.contains(key)) newlyActive.add(reminder);
      }

      final followUpData = followUpsBox.get(job.id);
      if (followUpData != null) {
        final responseStatus = followUpData['response_status'] as String? ?? 'sent';
        final sentAtRaw = followUpData['sent_at'] as String?;

        // Explicitly marked no_response → immediate reminder
        if (responseStatus == 'no_response') {
          final key = '${job.id}-${ReminderType.followUpNoResponse.name}';
          final reminder = Reminder(
            jobId: job.id,
            jobServiceType: job.serviceType,
            jobDate: job.jobDate,
            type: ReminderType.followUpNoResponse,
            amountCharged: job.amountCharged,
            isDismissed: dismissed.contains(key),
          );
          reminders.add(reminder);
          if (!dismissed.contains(key)) newlyActive.add(reminder);
        }

        // Sent but no response past threshold
        if (responseStatus == 'sent' && sentAtRaw != null) {
          final sentAt = DateTime.tryParse(sentAtRaw);
          if (sentAt != null && now.difference(sentAt).inDays >= t.followUpNoResponseDays) {
            final key = '${job.id}-${ReminderType.followUpNoResponse.name}';
            final reminder = Reminder(
              jobId: job.id,
              jobServiceType: job.serviceType,
              jobDate: job.jobDate,
              type: ReminderType.followUpNoResponse,
              amountCharged: job.amountCharged,
              isDismissed: dismissed.contains(key),
            );
            reminders.add(reminder);
            if (!dismissed.contains(key)) newlyActive.add(reminder);
          }
        }
      }
    }

    // Recurring job overdue reminders — check schedules past their due date
    final schedules = HiveService.recurringSchedules.values
        .map((e) => RecurringScheduleEntity(
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
        ))
        .where((s) => s.isActive && s.isDue)
        .toList();
    for (final schedule in schedules) {
      final daysOverdue = now.difference(schedule.nextDueDate).inDays;
      if (daysOverdue >= t.recurringJobOverdueDays) {
        final key = '${schedule.id}-${ReminderType.recurringJobOverdue.name}';
        final reminder = Reminder(
          jobId: schedule.id,
          jobServiceType: schedule.serviceType,
          jobDate: schedule.nextDueDate,
          type: ReminderType.recurringJobOverdue,
          isDismissed: dismissed.contains(key),
        );
        reminders.add(reminder);
        if (!dismissed.contains(key)) newlyActive.add(reminder);
      }
    }

    // Sort: undismissed first, then by jobDate descending
    reminders.sort((a, b) {
      if (a.isDismissed != b.isDismissed) return a.isDismissed ? 1 : -1;
      return b.jobDate.compareTo(a.jobDate);
    });

    state = RemindersState(reminders: reminders, dismissedKeys: dismissed);

    for (final r in newlyActive) {
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

final remindersProvider = StateNotifierProvider.autoDispose<RemindersNotifier, RemindersState>(
  (ref) {
    final notifier = RemindersNotifier(ref);
    // Recompute when job list changes
    ref.listen(jobListProvider, (_, __) => notifier.refresh());
    return notifier;
  });
