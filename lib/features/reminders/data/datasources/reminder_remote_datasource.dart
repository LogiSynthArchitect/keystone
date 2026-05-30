import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getReminders(String userId) async {
    return await _client
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> createReminder(Map<String, dynamic> data) async {
    await _client.from('reminders').insert(data);
  }

  Future<void> dismissReminder(String reminderId) async {
    await _client
        .from('reminders')
        .update({'status': 'dismissed', 'dismissed_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', reminderId);
  }

  Future<void> snoozeReminder(String reminderId, String snoozedUntil) async {
    await _client
        .from('reminders')
        .update({'status': 'snoozed', 'snoozed_until': snoozedUntil})
        .eq('id', reminderId);
  }

  Future<void> resolveReminder(String reminderId) async {
    await _client
        .from('reminders')
        .update({'status': 'resolved'})
        .eq('id', reminderId);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _client.from('reminders').delete().eq('id', reminderId);
  }
}
