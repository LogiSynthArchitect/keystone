import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/knowledge_note_entity.dart';
import '../../domain/repositories/knowledge_note_repository.dart';
import '../datasources/knowledge_note_local_datasource.dart';
import '../datasources/knowledge_note_remote_datasource.dart';
import '../models/knowledge_note_model.dart';
import '../../../../core/errors/auth_exception.dart';

class KnowledgeNoteRepositoryImpl implements KnowledgeNoteRepository {
  final KnowledgeNoteRemoteDatasource _remote;
  final KnowledgeNoteLocalDatasource _local;
  final SupabaseClient _supabase;
  final ConnectivityService _connectivity;

  KnowledgeNoteRepositoryImpl(this._remote, this._local, this._supabase, this._connectivity);

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException(message: 'Authentication session expired. Please log in again.', code: 'SESSION_EXPIRED');
    return id;
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
      debugPrint('[KS:NOTES] Remote getNoteById failed, falling back to local: $e');
      final localModels = await _local.getNotes();
      final local = localModels.where((m) => m.id == id).firstOrNull;
      if (local == null) throw Exception('Note not found (id=$id).');
      return local.toEntity();
    }
  }

  @override
  Future<KnowledgeNoteEntity> createNote(KnowledgeNoteEntity note) async {
    // Generate a stable local UUID so we can clean it up after remote sync.
    final localId = note.id.isNotEmpty ? note.id : const Uuid().v4();
    final localModel = KnowledgeNoteModel.fromEntity(note).copyWith(
      id: localId,
      syncStatus: 'pending',
    );
    await _local.saveNote(localModel);

    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final remoteModel = await _remote.createNote({
          'user_id': _userId,
          'title': note.title,
          'description': note.description,
          'tags': note.tags,
          'photo_url': note.photoUrl,
          'service_type': note.serviceType,
          'is_archived': false,
        });
        // Remove the local pending entry before saving the server version to
        // prevent duplicates if the remote assigned a different UUID.
        if (localId != remoteModel.id) {
          await _local.deleteNote(localId);
        }
        await _local.saveNote(remoteModel);
        return remoteModel.toEntity();
      } catch (e) {
        debugPrint('[KS:NOTES] Remote createNote failed, staying pending: $e');
      }
    }
    return localModel.toEntity();
  }

  @override
  Future<KnowledgeNoteEntity> updateNote(KnowledgeNoteEntity note) async {
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
        'service_type': note.serviceType,
      });
      
      await _local.saveNote(remoteModel);
      return remoteModel.toEntity();
    } catch (e) {
      return localModel.toEntity();
    }
  }

  @override
  Future<void> archiveNote(String id) async {
    // 1. Update locally first (offline-first guarantee)
    final localNotes = await _local.getNotes();
    final note = localNotes.where((n) => n.id == id).firstOrNull;
    if (note != null) await _local.saveNote(note.copyWith(isArchived: true));

    // 2. Attempt remote (best-effort, no retry mechanism yet)
    try {
      await _remote.archiveNote(id);
    } catch (e) {
      debugPrint('[KS:NOTES] Remote archiveNote failed, local state preserved: $e');
    }
  }

  @override
  Future<void> syncPendingNotes() async {
    if (!await _connectivity.isConnected) return;
    final pending = await _local.getPendingNotes();
    if (pending.isEmpty) return;
    for (final note in pending) {
      try {
        final remoteModel = await _remote.createNote({
          'user_id': _userId,
          'title': note.title,
          'description': note.description,
          'tags': note.tags,
          'photo_url': note.photoUrl,
          'service_type': note.serviceType,
          'is_archived': false,
        });
        // Step 1: Mark local copy as synced BEFORE deleting it.
        // If delete/save below fails, the note won't appear in the next getPendingNotes() —
        // preventing a duplicate from being created on the server.
        await _local.saveNote(note.copyWith(syncStatus: 'synced'));
        // Step 2: Replace local entry with the server copy (real server ID).
        if (note.id != remoteModel.id) {
          await _local.deleteNote(note.id);
        }
        await _local.saveNote(remoteModel);
      } catch (e) {
        debugPrint('[KS:NOTES] syncPendingNotes failed for ${note.id}: $e');
      }
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
