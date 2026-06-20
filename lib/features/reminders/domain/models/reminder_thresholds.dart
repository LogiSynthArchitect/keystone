import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';

class ReminderThresholds {
  final int unpaidJobDays;            // after how many days unpaid completed job triggers
  final int stuckInProgressDays;      // after how many days in-progress is "stuck"
  final int followUpPendingDays;      // after how many days no follow-up triggers
  final int followUpNoResponseDays;   // after how many days no response triggers
  final int recurringJobOverdueDays;  // after how many days a due schedule triggers
  final int dormantCustomerDays;      // after how many days since last job a customer is dormant

  const ReminderThresholds({
    this.unpaidJobDays = 1,
    this.stuckInProgressDays = 3,
    this.followUpPendingDays = 1,
    this.followUpNoResponseDays = 3,
    this.recurringJobOverdueDays = 2,
    this.dormantCustomerDays = 30,
  });

  ReminderThresholds copyWith({
    int? unpaidJobDays,
    int? stuckInProgressDays,
    int? followUpPendingDays,
    int? followUpNoResponseDays,
    int? recurringJobOverdueDays,
    int? dormantCustomerDays,
  }) => ReminderThresholds(
    unpaidJobDays: unpaidJobDays ?? this.unpaidJobDays,
    stuckInProgressDays: stuckInProgressDays ?? this.stuckInProgressDays,
    followUpPendingDays: followUpPendingDays ?? this.followUpPendingDays,
    followUpNoResponseDays: followUpNoResponseDays ?? this.followUpNoResponseDays,
    recurringJobOverdueDays: recurringJobOverdueDays ?? this.recurringJobOverdueDays,
    dormantCustomerDays: dormantCustomerDays ?? this.dormantCustomerDays,
  );

  static const _key = 'reminder_thresholds';

  static ReminderThresholds load() {
    try {
      final box = HiveService.settings;
      final data = box.get(_key);
      if (data is Map) {
        return ReminderThresholds(
          unpaidJobDays: data['unpaidJobDays'] as int? ?? 1,
          stuckInProgressDays: data['stuckInProgressDays'] as int? ?? 3,
          followUpPendingDays: data['followUpPendingDays'] as int? ?? 1,
          followUpNoResponseDays: data['followUpNoResponseDays'] as int? ?? 3,
          recurringJobOverdueDays: data['recurringJobOverdueDays'] as int? ?? 2,
          dormantCustomerDays: data['dormantCustomerDays'] as int? ?? 30,
        );
      }
    } catch (_) {}
    return const ReminderThresholds();
  }

  static Future<void> save(ReminderThresholds t) async {
    final box = HiveService.settings;
    await box.put(_key, {
      'unpaidJobDays': t.unpaidJobDays,
      'stuckInProgressDays': t.stuckInProgressDays,
      'followUpPendingDays': t.followUpPendingDays,
      'followUpNoResponseDays': t.followUpNoResponseDays,
      'recurringJobOverdueDays': t.recurringJobOverdueDays,
      'dormantCustomerDays': t.dormantCustomerDays,
    });
  }
}
