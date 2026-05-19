import '../entities/reminder_entity.dart';

abstract class ReminderRepository {
  Future<List<ReminderEntity>> getReminders(String userId);
  Future<void> createReminder(ReminderEntity reminder);
  Future<void> dismissReminder(String reminderId);
  Future<void> snoozeReminder(String reminderId, Duration duration);
  Future<void> resolveReminder(String reminderId);
}
