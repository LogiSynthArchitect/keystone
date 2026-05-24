import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/job_template_model.dart';

class JobTemplateRemoteDatasource {
  final SupabaseClient _supabase;
  JobTemplateRemoteDatasource(this._supabase);

  Future<List<JobTemplateModel>> getTemplates(String userId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobTemplatesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((json) => JobTemplateModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch templates.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<JobTemplateModel> saveTemplate(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobTemplatesTable)
          .upsert(json)
          .select()
          .single();
      return JobTemplateModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not save template.', code: 'SAVE_FAILED', cause: e);
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _supabase
          .from(SupabaseConstants.jobTemplatesTable)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete template.', code: 'DELETE_FAILED', cause: e);
    }
  }
}
