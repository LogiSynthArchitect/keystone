import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/key_code_entry_model.dart';

class KeyCodeRemoteDatasource {
  final SupabaseClient _supabase;
  KeyCodeRemoteDatasource(this._supabase);

  Future<List<KeyCodeEntryModel>> getForCustomer(String customerId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.keyCodeHistoryTable)
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return (data as List).map((json) => KeyCodeEntryModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch key codes.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<KeyCodeEntryModel> create(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.keyCodeHistoryTable)
          .insert(json)
          .select()
          .single();
      return KeyCodeEntryModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create key code.', code: 'CREATE_FAILED', cause: e);
    }
  }

  Future<KeyCodeEntryModel> update(String id, Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.keyCodeHistoryTable)
          .update(json)
          .eq('id', id)
          .select()
          .single();
      return KeyCodeEntryModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not update key code.', code: 'UPDATE_FAILED', cause: e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _supabase
          .from(SupabaseConstants.keyCodeHistoryTable)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete key code.', code: 'DELETE_FAILED', cause: e);
    }
  }
}
