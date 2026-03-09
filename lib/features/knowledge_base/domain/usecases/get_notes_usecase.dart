import '../../../../core/usecases/use_case.dart';
import '../entities/knowledge_note_entity.dart';
import '../repositories/knowledge_note_repository.dart';

class GetNotesUsecase implements NoParamsUseCase<List<KnowledgeNoteEntity>> {
  final KnowledgeNoteRepository _repository;
  GetNotesUsecase(this._repository);

  @override
  Future<List<KnowledgeNoteEntity>> call() => _repository.getNotes();
}
