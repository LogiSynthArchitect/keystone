import 'package:keystone/features/knowledge_base/domain/entities/note_job_link_entity.dart';
import '../repositories/note_link_repository.dart';

class CreateNoteLinkParams {
  final String noteId;
  final String jobId;
  final String userId;
  const CreateNoteLinkParams({required this.noteId, required this.jobId, required this.userId});
}

class CreateNoteLinkUsecase {
  final NoteLinkRepository _repository;
  CreateNoteLinkUsecase(this._repository);
  Future<NoteJobLinkEntity> call(CreateNoteLinkParams params) =>
      _repository.createLink(params.noteId, params.jobId, params.userId);
}
