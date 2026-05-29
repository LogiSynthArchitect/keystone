import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/recurring_schedule_model.dart';

class RecurringScheduleRemoteDatasource {
  final SupabaseClient _supabase;
  RecurringScheduleRemoteDatasource(this._supabase);

  Future<List<RecurringScheduleModel>> getAll(String userId) async {
    try {
      final data = await _supabase
          .from('recurring_job_schedules')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => RecurringScheduleModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch schedules.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<RecurringScheduleModel> upsert(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from('recurring_job_schedules')
          .upsert(json)
          .select()
          .single();
      return RecurringScheduleModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not save schedule.', code: 'SAVE_FAILED', cause: e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _supabase
          .from('recurring_job_schedules')
          .update({'sync_status': 'deleted'})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete schedule.', code: 'DELETE_FAILED', cause: e);
    }
  }
}
