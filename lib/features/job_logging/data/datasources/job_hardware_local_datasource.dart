import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_hardware_model.dart';

class JobHardwareLocalDatasource {
  Box get _box => HiveService.jobHardware;

  Future<List<JobHardwareModel>> getHardwareForJob(String jobId) async {
    return _box.values
        .map((json) => JobHardwareModel.fromJson(Map<String, dynamic>.from(json)))
        .where((h) => h.jobId == jobId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> saveHardware(JobHardwareModel model) async {
    await _box.put(model.id, model.toJson());
    await _box.flush();
  }

  Future<void> saveAll(List<JobHardwareModel> models) async {
    final map = {for (var m in models) m.id: m.toJson()};
    await _box.putAll(map);
    await _box.flush();
  }

  Future<void> deleteHardware(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Future<void> deleteHardwareForJob(String jobId) async {
    final keys = _box.values
        .where((json) => json['job_id'] == jobId)
        .map((json) => json['id'] as String)
        .toList();
    await _box.deleteAll(keys);
    await _box.flush();
  }

  /// Deletes specific keys (used by save-first-then-delete orphan cleanup).
  Future<void> deleteKeys(List<String> keys) async {
    if (keys.isEmpty) return;
    await _box.deleteAll(keys);
    await _box.flush();
  }
}

