import '../../../../core/usecases/use_case.dart';
import '../repositories/knowledge_note_repository.dart';

class ArchiveNoteUsecase implements UseCase<void, String> {
  final KnowledgeNoteRepository _repository;
  ArchiveNoteUsecase(this._repository);

  @override
  Future<void> call(String id) => _repository.archiveNote(id);
}
