import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/job_model.dart';

class JobRemoteDatasource {
  final SupabaseClient _supabase;
  JobRemoteDatasource(this._supabase);

  Future<List<JobModel>> getJobs({required String userId, int limit = 25, int offset = 0}) async {
    try {
      final data = await _supabase
          .from('jobs')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', false)
          .order('job_date', ascending: false)
          .range(offset, offset + limit - 1);
      return (data as List).map((e) => JobModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load jobs.', code: 'JOBS_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<JobModel> createJob(Map<String, dynamic> json) async {
    if (json['user_id'] == null || (json['user_id'] as String).isEmpty) {
      throw const NetworkException(message: 'Cannot create job: user_id is missing.', code: 'JOB_MISSING_USER_ID');
    }
    try {
      final data = await _supabase.from('jobs').insert(json).select().single();
      return JobModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not save your job.', code: 'JOB_CREATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<JobModel> updateJob(String id, Map<String, dynamic> json) async {
    try {
      final data = await _supabase.from('jobs').update(json).eq('id', id).select().single();
      return JobModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not update job.', code: 'JOB_UPDATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  /// Returns the server's current [updatedAt] for [id], or null if the job
  /// does not exist remotely yet.
  Future<DateTime?> fetchServerUpdatedAt(String id) async {
    try {
      final data = await _supabase
          .from('jobs')
          .select('updated_at')
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      final raw = data['updated_at'];
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  // Task 2: Return the RPC payload for cache reconciliation
  Future<Map<String, dynamic>> batchSync(String userId, List<Map<String, dynamic>> jobs) async {
    try {
      final response = await _supabase.rpc('batch_sync_jobs', params: {
        'p_user_id': userId,
        'p_jobs': jobs,
      });
      return response as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not sync jobs.', code: 'SYNC_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }
}
