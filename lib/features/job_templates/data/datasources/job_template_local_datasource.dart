import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_template_model.dart';

class JobTemplateLocalDatasource {
  Box get _box => HiveService.jobTemplates;

  Future<List<JobTemplateModel>> getAll() async {
    return _box.values
        .map((json) => JobTemplateModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Returns only non-deleted templates for UI display.
  Future<List<JobTemplateModel>> getAllActive() async {
    return _box.values
        .map((json) => JobTemplateModel.fromJson(Map<String, dynamic>.from(json)))
        .where((t) => !t.isDeleted)
        .toList();
  }

  Future<void> saveTemplate(JobTemplateModel model) async {
    await _box.put(model.id, model.toJson());
    await _box.flush();
  }

  Future<void> saveTemplates(List<JobTemplateModel> models) async {
    final map = {for (final m in models) m.id: m.toJson()};
    await _box.putAll(map);
    await _box.flush();
  }

  /// Soft-delete: sets is_deleted = true in local Hive.
  Future<void> softDeleteTemplate(String id) async {
    final raw = _box.get(id);
    if (raw == null) return;
    final model = JobTemplateModel.fromJson(Map<String, dynamic>.from(raw));
    await saveTemplate(model.copyWith(isDeleted: true));
  }

  /// Hard-delete: removes from local Hive entirely.
  /// Used when _syncFromRemote receives a tombstone row.
  Future<void> hardDeleteTemplate(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Future<void> renameTemplate(String id, String newName) async {
    final raw = _box.get(id);
    if (raw == null) return;
    final json = Map<String, dynamic>.from(raw as Map);
    json['name'] = newName;
    json['updated_at'] = DateTime.now().toIso8601String();
    await _box.put(id, json);
    await _box.flush();
  }
}
