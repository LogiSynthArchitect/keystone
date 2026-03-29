import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keystone/core/constants/supabase_constants.dart';
import 'package:keystone/core/errors/network_exception.dart';
import '../models/note_job_link_model.dart';

class NoteLinkRemoteDatasource {
  final SupabaseClient _supabase;
  NoteLinkRemoteDatasource(this._supabase);

  Future<List<NoteJobLinkModel>> getForNote(String noteId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.noteJobLinksTable)
          .select()
          .eq('note_id', noteId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => NoteJobLinkModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load links.', code: 'LINKS_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<List<NoteJobLinkModel>> getForJob(String jobId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.noteJobLinksTable)
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => NoteJobLinkModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load links.', code: 'LINKS_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<NoteJobLinkModel> create(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.noteJobLinksTable)
          .insert(json)
          .select()
          .single();
      return NoteJobLinkModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create link.', code: 'LINK_CREATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _supabase
          .from(SupabaseConstants.noteJobLinksTable)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete link.', code: 'LINK_DELETE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }
}
