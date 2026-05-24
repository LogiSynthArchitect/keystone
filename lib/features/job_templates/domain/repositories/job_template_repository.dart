import '../entities/job_template_entity.dart';

abstract class JobTemplateRepository {
  Future<List<JobTemplateEntity>> getTemplates(String userId);
  Future<JobTemplateEntity> saveTemplate(JobTemplateEntity template);
  Future<void> deleteTemplate(String id);
  Future<void> renameTemplate(String id, String newName);
}
