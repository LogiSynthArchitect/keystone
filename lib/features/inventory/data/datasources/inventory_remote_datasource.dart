import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/inventory_item_model.dart';

class InventoryRemoteDatasource {
  final SupabaseClient _supabase;
  InventoryRemoteDatasource(this._supabase);

  Future<List<InventoryItemModel>> getAll(String userId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.inventoryItemsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return (data as List).map((json) => InventoryItemModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch inventory.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<InventoryItemModel> create(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.inventoryItemsTable)
          .insert(json)
          .select()
          .single();
      return InventoryItemModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create inventory item.', code: 'CREATE_FAILED', cause: e);
    }
  }

  Future<InventoryItemModel> update(String id, Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.inventoryItemsTable)
          .update(json)
          .eq('id', id)
          .select()
          .single();
      return InventoryItemModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not update inventory item.', code: 'UPDATE_FAILED', cause: e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _supabase
          .from(SupabaseConstants.inventoryItemsTable)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete inventory item.', code: 'DELETE_FAILED', cause: e);
    }
  }
}
