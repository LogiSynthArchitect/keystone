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
    try {
      final data = await _supabase
          .from('follow_ups')
          .select()
          .eq('job_id', jobId)
          .maybeSingle();
      return data != null ? FollowUpModel.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load follow-up.', code: 'FOLLOWUP_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }
}
