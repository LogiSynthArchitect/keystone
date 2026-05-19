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

  Future<void> saveTemplate(JobTemplateModel model) async {
    await _box.put(model.id, model.toJson());
    await _box.flush();
  }

  Future<void> deleteTemplate(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Future<void> clear() async {
    await _box.clear();
    await _box.flush();
  }
}
