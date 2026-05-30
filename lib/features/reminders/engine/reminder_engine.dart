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

      if (job.isCompleted && job.paymentStatus == 'unpaid' && daysSince >= thresholds.unpaidJobDays) {
        _addJobReminder(reminders, newlyActive, job, ReminderType.unpaidJob, dismissedKeys);
      }

      if (job.status == 'in_progress' && daysSince >= thresholds.stuckInProgressDays) {
        _addJobReminder(reminders, newlyActive, job, ReminderType.stuckInProgress, dismissedKeys);
      }

      if (job.isCompleted && !job.followUpSent && daysSince >= thresholds.followUpPendingDays) {
        _addJobReminder(reminders, newlyActive, job, ReminderType.followUpPending, dismissedKeys);
      }

      final followUpData = followUps[job.id];
      if (followUpData != null) {
        final responseStatus = followUpData['response_status'] as String? ?? 'sent';
        final sentAtRaw = followUpData['sent_at'] as String?;

        if (responseStatus == 'no_response') {
          _addJobReminder(reminders, newlyActive, job, ReminderType.followUpNoResponse, dismissedKeys);
        }

        if (responseStatus == 'sent' && sentAtRaw != null) {
          final sentAt = DateTime.tryParse(sentAtRaw);
          if (sentAt != null && now.difference(sentAt).inDays >= thresholds.followUpNoResponseDays) {
            _addJobReminder(reminders, newlyActive, job, ReminderType.followUpNoResponse, dismissedKeys);
          }
        }
      }
    }

    for (final schedule in recurringSchedules) {
      if (!schedule.isActive || !schedule.isDue) continue;
      final daysOverdue = now.difference(schedule.nextDueDate).inDays;
      if (daysOverdue >= thresholds.recurringJobOverdueDays) {
        final key = '${schedule.id}-${ReminderType.recurringJobOverdue.name}';
        final reminder = Reminder(
          jobId: schedule.id,
          jobServiceType: schedule.serviceType,
          jobDate: schedule.nextDueDate,
          type: ReminderType.recurringJobOverdue,
          isDismissed: dismissedKeys.contains(key),
        );
        reminders.add(reminder);
        if (!dismissedKeys.contains(key)) {
          newlyActive.add(reminder);
        }
      }
    }

    reminders.sort((a, b) {
      if (a.isDismissed != b.isDismissed) return a.isDismissed ? 1 : -1;
      return b.jobDate.compareTo(a.jobDate);
    });

    return ReminderEngineResult(reminders: reminders, newlyActive: newlyActive);
  }

  static void _addJobReminder(
    List<Reminder> reminders,
    List<Reminder> newlyActive,
    JobEntity job,
    ReminderType type,
    Set<String> dismissedKeys,
  ) {
    final key = '${job.id}-${type.name}';
    final reminder = Reminder(
      jobId: job.id,
      jobServiceType: job.serviceType,
      jobDate: job.jobDate,
      type: type,
      amountCharged: job.amountCharged,
      isDismissed: dismissedKeys.contains(key),
    );
    reminders.add(reminder);
    if (!dismissedKeys.contains(key)) {
      newlyActive.add(reminder);
    }
  }
}
