import '../repositories/knowledge_note_repository.dart';

class SyncPendingNotesUsecase {
  final KnowledgeNoteRepository _repository;

  SyncPendingNotesUsecase(this._repository);

  Future<void> call() async {
    return _repository.syncPendingNotes();
  }
}
