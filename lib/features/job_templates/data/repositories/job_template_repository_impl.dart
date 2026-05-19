import '../datasources/job_template_local_datasource.dart';
import '../models/job_template_model.dart';
import '../../domain/entities/job_template_entity.dart';
import '../../domain/repositories/job_template_repository.dart';

class JobTemplateRepositoryImpl implements JobTemplateRepository {
  final JobTemplateLocalDatasource _local;

  JobTemplateRepositoryImpl(this._local);

  @override
  Future<List<JobTemplateEntity>> getTemplates(String userId) async {
    final models = await _local.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<JobTemplateEntity> saveTemplate(JobTemplateEntity template) async {
    final model = JobTemplateModel.fromEntity(template);
    await _local.saveTemplate(model);
    return model.toEntity();
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _local.deleteTemplate(id);
  }
}
