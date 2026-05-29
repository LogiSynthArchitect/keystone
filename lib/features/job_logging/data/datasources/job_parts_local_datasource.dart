import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_part_model.dart';

class JobPartsLocalDatasource {
  Box get _box => HiveService.jobParts;

  Future<List<JobPartModel>> getPartsForJob(String jobId) async {
    return _box.values
        .map((json) => JobPartModel.fromJson(Map<String, dynamic>.from(json)))
        .where((part) => part.jobId == jobId)
        .toList();
  }

  Future<void> savePart(JobPartModel model) async {
    await _box.put(model.id, model.toJson());
    await _box.flush();
  }

  Future<void> saveAll(List<JobPartModel> models) async {
    final Map<String, Map> map = {
      for (var m in models) m.id: m.toJson(),
    };
    await _box.putAll(map);
    await _box.flush();
  }

  Future<void> deletePart(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Future<void> deletePartsForJob(String jobId) async {
    final keysToDelete = _box.values
        .where((json) => json['job_id'] == jobId)
        .map((json) => json['id'] as String)
        .toList();
    
    await _box.deleteAll(keysToDelete);
    await _box.flush();
  }

  /// Deletes specific keys (used by save-first-then-delete + WAL orphan cleanup).
  Future<void> deleteKeys(List<String> keys) async {
    if (keys.isEmpty) return;
    await _box.deleteAll(keys);
    await _box.flush();
  }
}
