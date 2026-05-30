import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/reminder_entity.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_datasource.dart';
import '../models/reminder_model.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDatasource _remote;

  ReminderRepositoryImpl(this._remote);

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  Future<List<ReminderEntity>> getReminders(String userId) async {
    try {
      final data = await _remote.getReminders(userId);
      return data.map((json) => ReminderModel.fromJson(json)).toList();
    } catch (e) {
      print('[KS:REMINDERS] Failed to fetch reminders: $e');
      return [];
    }
  }

  @override
  Future<void> createReminder(ReminderEntity reminder) async {
    try {
      await _remote.createReminder({
        'id': reminder.id,
        'user_id': _userId,
        'job_id': reminder.jobId,
        'type': reminder.type,
        'status': reminder.status,
        'created_at': reminder.createdAt.toUtc().toIso8601String(),
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
