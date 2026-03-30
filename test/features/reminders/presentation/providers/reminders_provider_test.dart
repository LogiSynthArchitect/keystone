import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/features/reminders/domain/models/reminder_model.dart';

void main() {
  group('Reminder model', () {
    final reminder = Reminder(
      jobId: 'job-1',
      jobServiceType: 'car lock',
      jobDate: DateTime(2026, 1, 15),
      type: ReminderType.unpaidJob,
      amountCharged: 20000,
    );

    test('isDismissed defaults to false', () {
      expect(reminder.isDismissed, isFalse);
    });

    test('copyWith isDismissed updates correctly', () {
      final dismissed = reminder.copyWith(isDismissed: true);
      expect(dismissed.isDismissed, isTrue);
      expect(dismissed.jobId, equals('job-1'));
    });

    test('ReminderType.unpaidJob has correct label', () {
      expect(ReminderType.unpaidJob.label, equals('UNPAID JOB'));
    });

    test('ReminderType.stuckInProgress has correct label', () {
      expect(ReminderType.stuckInProgress.label, equals('JOB IN PROGRESS'));
    });

    test('ReminderType.followUpPending has correct label', () {
      expect(ReminderType.followUpPending.label, equals('FOLLOW-UP NEEDED'));
    });
  });
}
