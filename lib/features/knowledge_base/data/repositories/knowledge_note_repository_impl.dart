import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/knowledge_note_entity.dart';
import '../../domain/repositories/knowledge_note_repository.dart';
import '../datasources/knowledge_note_local_datasource.dart';
import '../datasources/knowledge_note_remote_datasource.dart';
import '../models/knowledge_note_model.dart';

class KnowledgeNoteRepositoryImpl implements KnowledgeNoteRepository {
  final KnowledgeNoteRemoteDatasource _remote;
  final KnowledgeNoteLocalDatasource _local;
  final SupabaseClient _supabase;

  KnowledgeNoteRepositoryImpl(this._remote, this._local, this._supabase);

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
  Future<List<KnowledgeNoteEntity>> getNotes({int limit = 25, int offset = 0, bool includeArchived = false}) async {
    try {
      final remoteModels = await _remote.getNotes(userId: _userId, limit: limit, offset: offset, includeArchived: includeArchived);
      await _local.saveNotes(remoteModels);
      return remoteModels.map((m) => m.toEntity()).toList();
    } catch (e) {
      // Offline: return local notes
      var localModels = await _local.getNotes();
      if (!includeArchived) {
        localModels = localModels.where((m) => !m.isArchived).toList();
      }
      return localModels.map((m) => m.toEntity()).toList();
    }
  }

  @override
  Future<KnowledgeNoteEntity> getNoteById(String id) async {
    try {
      final remoteModels = await _remote.getNotes(userId: _userId, limit: 1000, offset: 0);
      final model = remoteModels.firstWhere((m) => m.id == id);
      await _local.saveNote(model);
      return model.toEntity();
    } catch (e) {
      final localModels = await _local.getNotes();
      return localModels.firstWhere((m) => m.id == id).toEntity();
    }
  }

  @override
  Future<KnowledgeNoteEntity> createNote(KnowledgeNoteEntity note) async {
    final serviceTypeDb = note.serviceType != null ? _serviceTypeToDb(note.serviceType!.name) : null;
    
    // Save locally first
    final localModel = KnowledgeNoteModel.fromEntity(note).copyWith(
      syncStatus: 'pending',
    );
    await _local.saveNote(localModel);

    try {
      final remoteModel = await _remote.createNote({
        'user_id': _userId,
        'title': note.title,
        'description': note.description,
        'tags': note.tags,
        'photo_url': note.photoUrl,
        'service_type': serviceTypeDb,
        'is_archived': false,
      });
      
      // Update local with remote data and 'synced' status
      await _local.saveNote(remoteModel);
      return remoteModel.toEntity();
    } catch (e) {
      // Stay pending
      return localModel.toEntity();
    }
  }

  @override
  Future<KnowledgeNoteEntity> updateNote(KnowledgeNoteEntity note) async {
    final serviceTypeDb = note.serviceType != null ? _serviceTypeToDb(note.serviceType!.name) : null;
    
    // Update local first
    final localModel = KnowledgeNoteModel.fromEntity(note).copyWith(
      syncStatus: 'pending',
    );
    await _local.saveNote(localModel);

    try {
      final remoteModel = await _remote.updateNote(note.id, {
        'title': note.title,
        'description': note.description,
        'tags': note.tags,
        'photo_url': note.photoUrl,
        'service_type': serviceTypeDb,
      });
      
      await _local.saveNote(remoteModel);
      return remoteModel.toEntity();
    } catch (e) {
      return localModel.toEntity();
    }
  }

  @override
  Future<void> archiveNote(String id) async {
    try {
      await _remote.archiveNote(id);
      // Update local if remote succeeds
      final localNotes = await _local.getNotes();
      final note = localNotes.firstWhere((n) => n.id == id);
      await _local.saveNote(note.copyWith(isArchived: true));
    } catch (e) {
      // In a real app, we might mark this for sync as well
      rethrow;
    }
  }

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
