import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import '../../domain/models/reminder_model.dart';

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

  RemindersNotifier(this._ref) : super(const RemindersState()) {
    _compute();
  }

  void _compute() {
    final jobs = _ref.read(jobListProvider).activeJobs;
    final now = DateTime.now();
    final dismissed = state.dismissedKeys;
    final reminders = <Reminder>[];
    final followUpsBox = HiveService.followUps;

    for (final job in jobs) {
      final daysSince = now.difference(job.jobDate).inDays;

      // Unpaid completed jobs older than 1 day
      if (job.status == 'completed' && job.paymentStatus == 'unpaid' && daysSince >= 1) {
        final key = '${job.id}-${ReminderType.unpaidJob.name}';
        reminders.add(Reminder(
          jobId: job.id,
          jobServiceType: job.serviceType,
          jobDate: job.jobDate,
          type: ReminderType.unpaidJob,
          amountCharged: job.amountCharged,
          isDismissed: dismissed.contains(key),
        ));
      }

      // Jobs stuck in-progress for more than 3 days
      if (job.status == 'in_progress' && daysSince >= 3) {
        final key = '${job.id}-${ReminderType.stuckInProgress.name}';
        reminders.add(Reminder(
          jobId: job.id,
          jobServiceType: job.serviceType,
          jobDate: job.jobDate,
          type: ReminderType.stuckInProgress,
          amountCharged: job.amountCharged,
          isDismissed: dismissed.contains(key),
        ));
      }

      // Jobs with no follow-up sent, completed, older than 1 day
      if (job.status == 'completed' && !job.followUpSent && daysSince >= 1) {
        final key = '${job.id}-${ReminderType.followUpPending.name}';
        reminders.add(Reminder(
          jobId: job.id,
          jobServiceType: job.serviceType,
          jobDate: job.jobDate,
          type: ReminderType.followUpPending,
          amountCharged: job.amountCharged,
          isDismissed: dismissed.contains(key),
        ));
      }

      // Follow-ups sent more than 3 days ago with no response
      final followUpData = followUpsBox.get(job.id);
      if (followUpData != null) {
        final responseStatus = followUpData['response_status'] as String? ?? 'sent';
        final sentAtRaw = followUpData['sent_at'] as String?;
        if (responseStatus == 'sent' && sentAtRaw != null) {
          final sentAt = DateTime.tryParse(sentAtRaw);
          if (sentAt != null && now.difference(sentAt).inDays >= 3) {
            final key = '${job.id}-${ReminderType.followUpNoResponse.name}';
            reminders.add(Reminder(
              jobId: job.id,
              jobServiceType: job.serviceType,
              jobDate: job.jobDate,
              type: ReminderType.followUpNoResponse,
              amountCharged: job.amountCharged,
              isDismissed: dismissed.contains(key),
            ));
          }
        }
      }
    }

    // Sort: undismissed first, then by jobDate descending
    reminders.sort((a, b) {
      if (a.isDismissed != b.isDismissed) return a.isDismissed ? 1 : -1;
      return b.jobDate.compareTo(a.jobDate);
    });

    state = RemindersState(reminders: reminders, dismissedKeys: dismissed);
  }

  void dismiss(String jobId, ReminderType type) {
    final key = '$jobId-${type.name}';
    final newDismissed = {...state.dismissedKeys, key};
    final updated = state.reminders.map((r) {
      if (r.jobId == jobId && r.type == type) return r.copyWith(isDismissed: true);
      return r;
    }).toList();
    state = RemindersState(reminders: updated, dismissedKeys: newDismissed);
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
