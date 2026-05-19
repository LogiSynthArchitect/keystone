import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/job_service_model.dart';

class JobServicesRemoteDatasource {
  final SupabaseClient _supabase;
  JobServicesRemoteDatasource(this._supabase);

  Future<List<JobServiceModel>> getServicesForJob(String jobId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobServicesTable)
          .select()
          .eq('job_id', jobId)
          .order('sort_order');
      return (data as List).map((json) => JobServiceModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch job services.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<JobServiceModel> createService(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobServicesTable)
          .insert(json)
          .select()
          .single();
      return JobServiceModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create job service.', code: 'CREATE_FAILED', cause: e);
    }
  }

  Future<void> deleteService(String id) async {
    try {
      await _supabase.from(SupabaseConstants.jobServicesTable).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete job service.', code: 'DELETE_FAILED', cause: e);
    }
  }

  Future<List<JobServiceModel>> upsertAll(List<Map<String, dynamic>> jsonList) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobServicesTable)
          .upsert(jsonList)
          .select();
      return (data as List).map((json) => JobServiceModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not sync job services.', code: 'UPSERT_FAILED', cause: e);
    }
  }
}

