import '../entities/knowledge_note_entity.dart';
import '../repositories/knowledge_note_repository.dart';

class GetNotesUsecase {
  final KnowledgeNoteRepository _repository;
  GetNotesUsecase(this._repository);

  Future<List<KnowledgeNoteEntity>> call({bool includeArchived = false}) => 
    _repository.getNotes(includeArchived: includeArchived);
}
