import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/knowledge_note_model.dart';

class KnowledgeNoteRemoteDatasource {
  final SupabaseClient _supabase;
  KnowledgeNoteRemoteDatasource(this._supabase);

  Future<List<KnowledgeNoteModel>> getNotes({required String userId, int limit = 25, int offset = 0, bool includeArchived = false}) async {
    try {
      var query = _supabase
          .from('knowledge_notes')
          .select()
          .eq('user_id', userId);
      
      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (data as List).map((e) => KnowledgeNoteModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load notes.', code: 'NOTES_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<KnowledgeNoteModel> createNote(Map<String, dynamic> json) async {
    try {
      final data = await _supabase.from('knowledge_notes').insert(json).select().single();
      return KnowledgeNoteModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not save note.', code: 'NOTE_CREATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<KnowledgeNoteModel> updateNote(String id, Map<String, dynamic> json) async {
    try {
      final data = await _supabase.from('knowledge_notes').update(json).eq('id', id).select().single();
      return KnowledgeNoteModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not update note.', code: 'NOTE_UPDATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<void> archiveNote(String id) async {
    try {
      await _supabase.from('knowledge_notes').update({'is_archived': true}).eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not archive note.', code: 'NOTE_ARCHIVE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }
}
