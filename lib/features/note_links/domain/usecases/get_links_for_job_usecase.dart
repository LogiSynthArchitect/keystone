import 'package:keystone/features/knowledge_base/domain/entities/note_job_link_entity.dart';
import '../repositories/note_link_repository.dart';

class GetLinksForJobUsecase {
  final NoteLinkRepository _repository;
  GetLinksForJobUsecase(this._repository);
  Future<List<NoteJobLinkEntity>> call(String jobId) => _repository.getLinksForJob(jobId);
}
