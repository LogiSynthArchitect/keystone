import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/job_part_model.dart';

class JobPartsRemoteDatasource {
  final SupabaseClient _supabase;
  JobPartsRemoteDatasource(this._supabase);

  Future<List<JobPartModel>> getPartsForJob(String jobId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobPartsTable)
          .select()
          .eq('job_id', jobId);
      return (data as List).map((json) => JobPartModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch job parts.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<JobPartModel> createPart(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobPartsTable)
          .insert(json)
          .select()
          .single();
      return JobPartModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create job part.', code: 'CREATE_FAILED', cause: e);
    }
  }

  Future<void> deletePart(String id) async {
    try {
      await _supabase
          .from(SupabaseConstants.jobPartsTable)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete job part.', code: 'DELETE_FAILED', cause: e);
    }
  }

  Future<List<JobPartModel>> upsertAll(List<Map<String, dynamic>> jsonList) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobPartsTable)
          .upsert(jsonList)
          .select();
      return (data as List).map((json) => JobPartModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not sync job parts.', code: 'UPSERT_FAILED', cause: e);
    }
  }
}
