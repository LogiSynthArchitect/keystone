import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_service_model.dart';

class JobServicesLocalDatasource {
  Box get _box => HiveService.jobServices;

  Future<List<JobServiceModel>> getServicesForJob(String jobId) async {
    return _box.values
        .map((json) => JobServiceModel.fromJson(Map<String, dynamic>.from(json)))
        .where((s) => s.jobId == jobId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> saveService(JobServiceModel model) async {
    await _box.put(model.id, model.toJson());
    await _box.flush();
  }

  Future<void> saveAll(List<JobServiceModel> models) async {
    final map = {for (var m in models) m.id: m.toJson()};
    await _box.putAll(map);
    await _box.flush();
  }

  Future<void> deleteService(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Future<void> deleteServicesForJob(String jobId) async {
    final keys = _box.values
        .where((json) => json['job_id'] == jobId)
        .map((json) => json['id'] as String)
        .toList();
    await _box.deleteAll(keys);
    await _box.flush();
  }
}

