import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/knowledge_note_entity.dart';
import '../../domain/repositories/knowledge_note_repository.dart';
import '../datasources/knowledge_note_remote_datasource.dart';

class KnowledgeNoteRepositoryImpl implements KnowledgeNoteRepository {
  final KnowledgeNoteRemoteDatasource _remote;
  final SupabaseClient _supabase;
  KnowledgeNoteRepositoryImpl(this._remote, this._supabase);
  String get _userId => _supabase.auth.currentUser!.id;

  String _serviceTypeToDb(String camelCase) {
    switch (camelCase) {
      case 'carLockProgramming':    return 'car_lock_programming';
      case 'doorLockInstallation':  return 'door_lock_installation';
      case 'doorLockRepair':        return 'door_lock_repair';
      case 'smartLockInstallation': return 'smart_lock_installation';
      default:                      return camelCase;
    }
  }

  @override
  Future<List<KnowledgeNoteEntity>> getNotes({int limit = 25, int offset = 0}) async {
    final models = await _remote.getNotes(userId: _userId, limit: limit, offset: offset);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<KnowledgeNoteEntity> getNoteById(String id) async {
    final models = await _remote.getNotes(userId: _userId, limit: 1000, offset: 0);
    return models.firstWhere((m) => m.id == id).toEntity();
  }

  @override
  Future<KnowledgeNoteEntity> createNote(KnowledgeNoteEntity note) async {
    final serviceTypeDb = note.serviceType != null ? _serviceTypeToDb(note.serviceType!.name) : null;
    final model = await _remote.createNote({
      'user_id': _userId,
      'title': note.title,
      'description': note.description,
      'tags': note.tags,
      'photo_url': note.photoUrl,
      'service_type': serviceTypeDb,
      'is_archived': false,
    });
    return model.toEntity();
  }

  @override
  Future<KnowledgeNoteEntity> updateNote(KnowledgeNoteEntity note) async {
    final serviceTypeDb = note.serviceType != null ? _serviceTypeToDb(note.serviceType!.name) : null;
    final model = await _remote.updateNote(note.id, {
      'title': note.title,
      'description': note.description,
      'tags': note.tags,
      'photo_url': note.photoUrl,
      'service_type': serviceTypeDb,
    });
    return model.toEntity();
  }

  @override
  Future<void> archiveNote(String id) => _remote.archiveNote(id);

  @override
  Future<List<KnowledgeNoteEntity>> searchNotes(String query) async {
    final all = await getNotes(limit: 1000);
    final q = query.toLowerCase();
    return all.where((n) =>
      n.title.toLowerCase().contains(q) ||
      n.description.toLowerCase().contains(q) ||
      n.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }

  @override
  Future<List<KnowledgeNoteEntity>> getNotesByTag(String tag) async {
    final all = await getNotes(limit: 1000);
    return all.where((n) => n.tags.contains(tag)).toList();
  }
}
