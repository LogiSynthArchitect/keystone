import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/knowledge_note_model.dart';

class KnowledgeNoteLocalDatasource {
  Box<Map> get _box => HiveService.notes;

  Future<void> saveNote(KnowledgeNoteModel note) async {
    try {
      await _box.put(note.id, note.toJson().cast<String, dynamic>());
      await _box.flush(); // Force immediate disk persistence
    } catch (e) {
      throw StorageException(
        message: 'Could not save note locally.',
        code: 'LOCAL_SAVE_FAILED',
        cause: e,
      );
    }
  }

  Future<void> saveNotes(List<KnowledgeNoteModel> notes) async {
    try {
      final Map<String, Map<String, dynamic>> entries = {
        for (var note in notes) note.id: note.toJson().cast<String, dynamic>()
      };
      await _box.putAll(entries);
    } catch (e) {
      throw StorageException(
        message: 'Could not save notes locally.',
        code: 'LOCAL_BATCH_SAVE_FAILED',
        cause: e,
      );
    }
  }

  Future<List<KnowledgeNoteModel>> getNotes() async {
    try {
      return _box.values
          .map((e) => KnowledgeNoteModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw StorageException(
        message: 'Could not read local notes.',
        code: 'LOCAL_READ_FAILED',
        cause: e,
      );
    }
  }

  Future<void> updateSyncStatus(String id, String status) async {
    try {
      final existing = _box.get(id);
      if (existing != null) {
        final updated = Map<String, dynamic>.from(existing);
        updated['sync_status'] = status;
        await _box.put(id, updated);
      }
    } catch (e) {
      throw StorageException(
        message: 'Could not update sync status.',
        code: 'LOCAL_UPDATE_FAILED',
        cause: e,
      );
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageException(
        message: 'Could not delete local note.',
        code: 'LOCAL_DELETE_FAILED',
        cause: e,
      );
    }
  }

  Future<List<KnowledgeNoteModel>> getPendingNotes() async {
    final all = await getNotes();
    return all.where((n) => n.syncStatus == 'pending').toList();
  }
}
