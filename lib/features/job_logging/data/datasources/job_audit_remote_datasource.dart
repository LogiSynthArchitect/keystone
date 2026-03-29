import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/job_audit_entry_model.dart';

class JobAuditRemoteDatasource {
  final SupabaseClient _supabase;
  JobAuditRemoteDatasource(this._supabase);

  Future<List<JobAuditEntryModel>> getEntriesForJob(String jobId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobAuditLogTable)
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);
      return (data as List).map((json) => JobAuditEntryModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch audit log.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<JobAuditEntryModel> insertEntry(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobAuditLogTable)
          .insert(json)
          .select()
          .single();
      return JobAuditEntryModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create audit entry.', code: 'CREATE_FAILED', cause: e);
    }
  }

  Future<void> insertAll(List<Map<String, dynamic>> jsonList) async {
    try {
      await _supabase
          .from(SupabaseConstants.jobAuditLogTable)
          .insert(jsonList);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not sync audit log.', code: 'SYNC_FAILED', cause: e);
    }
  }
}
