import 'package:keystone/features/knowledge_base/domain/entities/note_job_link_entity.dart';
import '../repositories/note_link_repository.dart';

class GetLinksForNoteUsecase {
  final NoteLinkRepository _repository;
  GetLinksForNoteUsecase(this._repository);
  Future<List<NoteJobLinkEntity>> call(String noteId) => _repository.getLinksForNote(noteId);
}
