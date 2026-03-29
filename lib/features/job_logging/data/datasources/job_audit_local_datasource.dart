import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_audit_entry_model.dart';

class JobAuditLocalDatasource {
  Box<Map> get _box => HiveService.jobAuditLog;

  Future<List<JobAuditEntryModel>> getEntriesForJob(String jobId) async {
    return _box.values
        .map((json) => JobAuditEntryModel.fromJson(Map<String, dynamic>.from(json)))
        .where((entry) => entry.jobId == jobId)
        .toList();
  }

  Future<void> saveEntry(JobAuditEntryModel model) async {
    await _box.put(model.id, model.toJson());
    await _box.flush();
  }

  Future<void> saveAll(List<JobAuditEntryModel> models) async {
    final Map<String, Map> map = {
      for (var m in models) m.id: m.toJson(),
    };
    await _box.putAll(map);
    await _box.flush();
  }
}
