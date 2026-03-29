import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/job_photo_model.dart';

class JobPhotosRemoteDatasource {
  final SupabaseClient _supabase;
  JobPhotosRemoteDatasource(this._supabase);

  Future<List<JobPhotoModel>> getPhotosForJob(String jobId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobPhotosTable)
          .select()
          .eq('job_id', jobId);
      return (data as List).map((json) => JobPhotoModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch job photos.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<String> uploadPhoto({
    required String jobId,
    required String userId,
    required File file,
    required String photoType, // 'before' | 'after'
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$jobId/$photoType/$fileName';
      
      await _supabase.storage.from('job-photos').upload(path, file);
      
      final publicUrl = _supabase.storage.from('job-photos').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw NetworkException(message: 'Could not upload job photo.', code: 'UPLOAD_FAILED', cause: e);
    }
  }

  Future<JobPhotoModel> createPhotoRecord(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobPhotosTable)
          .insert(json)
          .select()
          .single();
      return JobPhotoModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not save job photo record.', code: 'CREATE_FAILED', cause: e);
    }
  }

  Future<void> deletePhoto(String id, String storagePath) async {
    try {
      // 1. Delete from storage
      await _supabase.storage.from('job-photos').remove([storagePath]);
      
      // 2. Delete record
      await _supabase
          .from(SupabaseConstants.jobPhotosTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw NetworkException(message: 'Could not delete job photo.', code: 'DELETE_FAILED', cause: e);
    }
  }
}
