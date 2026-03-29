import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_photo_model.dart';

class JobPhotosLocalDatasource {
  Box<Map> get _box => HiveService.jobPhotos;

  Future<List<JobPhotoModel>> getPhotosForJob(String jobId) async {
    return _box.values
        .map((json) => JobPhotoModel.fromJson(Map<String, dynamic>.from(json)))
        .where((photo) => photo.jobId == jobId)
        .toList();
  }

  Future<void> savePhoto(JobPhotoModel model) async {
    await _box.put(model.id, model.toJson());
    await _box.flush();
  }

  Future<void> deletePhoto(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Future<void> deletePhotosForJob(String jobId) async {
    final keysToDelete = _box.values
        .where((json) => json['job_id'] == jobId)
        .map((json) => json['id'] as String)
        .toList();
    
    await _box.deleteAll(keysToDelete);
    await _box.flush();
  }
}
