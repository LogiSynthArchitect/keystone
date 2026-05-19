import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/job_hardware_model.dart';

class JobHardwareRemoteDatasource {
  final SupabaseClient _supabase;
  JobHardwareRemoteDatasource(this._supabase);

  Future<List<JobHardwareModel>> getHardwareForJob(String jobId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobHardwareTable)
          .select()
          .eq('job_id', jobId)
          .order('sort_order');
      return (data as List).map((json) => JobHardwareModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch job hardware.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<JobHardwareModel> createHardware(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobHardwareTable)
          .insert(json)
          .select()
          .single();
      return JobHardwareModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create job hardware.', code: 'CREATE_FAILED', cause: e);
    }
  }

  Future<void> deleteHardware(String id) async {
    try {
      await _supabase.from(SupabaseConstants.jobHardwareTable).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete job hardware.', code: 'DELETE_FAILED', cause: e);
    }
  }

  Future<List<JobHardwareModel>> upsertAll(List<Map<String, dynamic>> jsonList) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobHardwareTable)
          .upsert(jsonList)
          .select();
      return (data as List).map((json) => JobHardwareModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not sync job hardware.', code: 'UPSERT_FAILED', cause: e);
    }
  }
}

