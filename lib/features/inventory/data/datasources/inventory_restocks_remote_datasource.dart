import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/restock_model.dart';

class InventoryRestocksRemoteDatasource {
  final SupabaseClient _supabase;
  InventoryRestocksRemoteDatasource(this._supabase);

  Future<List<RestockModel>> getForItem(String itemId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.inventoryRestocksTable)
          .select()
          .eq('item_id', itemId)
          .order('created_at', ascending: false);
      return (data as List).map((json) => RestockModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch restocks.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<RestockModel> create(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.inventoryRestocksTable)
          .insert(json)
          .select()
          .single();
      return RestockModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create restock.', code: 'CREATE_FAILED', cause: e);
    }
  }
}
