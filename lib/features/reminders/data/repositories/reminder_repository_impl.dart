import '../../domain/entities/reminder_entity.dart';
import '../../domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  @override
  Future<List<ReminderEntity>> getReminders(String userId) async {
    // TODO: Query Supabase reminders table
    return [];
  }

  @override
  Future<void> createReminder(ReminderEntity reminder) async {
    // TODO: Insert into Supabase
  }

  @override
  Future<void> dismissReminder(String reminderId) async {
    // TODO: Update status='dismissed', dismissed_at=now
  }

  @override
  Future<void> snoozeReminder(String reminderId, Duration duration) async {
    // TODO: Update status='snoozed', snoozed_until=now+duration
  }

  @override
  Future<void> resolveReminder(String reminderId) async {
    // TODO: Update status='resolved'
  }
}
