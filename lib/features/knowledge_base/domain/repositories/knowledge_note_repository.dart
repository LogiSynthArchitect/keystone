import '../entities/knowledge_note_entity.dart';

abstract class KnowledgeNoteRepository {
  Future<List<KnowledgeNoteEntity>> getNotes({int limit = 25, int offset = 0, bool includeArchived = false});
  Future<KnowledgeNoteEntity> getNoteById(String id);
  Future<KnowledgeNoteEntity> createNote(KnowledgeNoteEntity note);
  Future<KnowledgeNoteEntity> updateNote(KnowledgeNoteEntity note);
  Future<void> archiveNote(String id);
  Future<List<KnowledgeNoteEntity>> searchNotes(String query);
  Future<List<KnowledgeNoteEntity>> getNotesByTag(String tag);
}
