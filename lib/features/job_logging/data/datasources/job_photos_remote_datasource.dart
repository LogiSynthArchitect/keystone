import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/pending_media_upload_service.dart';
import '../models/job_photo_model.dart';

class JobPhotosRemoteDatasource {
  final SupabaseClient _supabase;
  final CloudinaryService _cloudinary;
  JobPhotosRemoteDatasource(this._supabase) : _cloudinary = CloudinaryService();

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

  Future<String?> uploadMedia({
    required String jobId,
    required String userId,
    required File file,
    required String mediaType,
    required String label,
  }) async {
    try {
      final cloudUrl = await _cloudinary.uploadMedia(
        file: file,
        publicId: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (cloudUrl != null) return cloudUrl;

      final ext = switch (mediaType) {
        'video' => '.mp4',
        'audio' => '.mp3',
        _ => '.jpg',
      };
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final path = '$userId/$jobId/$label/$fileName';
      
      await _supabase.storage.from('job-photos').upload(path, file);

      final publicUrl = await _supabase.storage.from('job-photos').createSignedUrl(path, 7 * 24 * 3600);
      return publicUrl;
    } catch (_) {
      try {
        final svc = PendingMediaUploadService();
        await svc.enqueue(PendingMediaUpload(
          id: const Uuid().v4(),
          filePath: file.path,
          jobId: jobId,
          userId: userId,
          mediaType: mediaType,
          label: label,
          createdAt: DateTime.now(),
        ));
        debugPrint('[KS:MEDIA] Upload failed, queued for later retry');
      } catch (e) {
        debugPrint('[KS:MEDIA] Failed to enqueue pending upload: $e');
      }
      return null;
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
      if (storagePath.contains('res.cloudinary.com')) {
        await _cloudinary.deleteMedia(storagePath);
      } else {
        await _supabase.storage.from('job-photos').remove([storagePath]);
      }
      await _supabase
          .from(SupabaseConstants.jobPhotosTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw NetworkException(message: 'Could not delete job photo.', code: 'DELETE_FAILED', cause: e);
    }
  }
}
