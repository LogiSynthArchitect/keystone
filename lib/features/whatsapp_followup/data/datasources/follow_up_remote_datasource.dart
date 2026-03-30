import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/follow_up_model.dart';

class FollowUpRemoteDatasource {
  final SupabaseClient _supabase;
  FollowUpRemoteDatasource(this._supabase);

  Future<FollowUpModel> createFollowUp(Map<String, dynamic> json) async {
    try {
      final data = await _supabase.from('follow_ups').insert(json).select().single();
      return FollowUpModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not record follow-up.', code: 'FOLLOWUP_CREATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<FollowUpModel?> getFollowUpByJobId(String jobId) async {
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(jobId)) return null;
    try {
      final data = await _supabase.from('follow_ups').select().eq('job_id', jobId).maybeSingle();
      return data != null ? FollowUpModel.fromJson(data) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateResponseStatus(String jobId, String status) async {
    try {
      await _supabase
          .from('follow_ups')
          .update({
            'response_status': status,
            'response_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not update follow-up status.', code: 'FOLLOWUP_STATUS_REMOTE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }
}
