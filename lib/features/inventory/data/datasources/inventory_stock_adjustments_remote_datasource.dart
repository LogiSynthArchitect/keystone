import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/stock_adjustment_model.dart';

class InventoryStockAdjustmentsRemoteDatasource {
  final SupabaseClient _supabase;
  InventoryStockAdjustmentsRemoteDatasource(this._supabase);

  Future<List<StockAdjustmentModel>> getForItem(String itemId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.inventoryStockAdjustmentsTable)
          .select()
          .eq('item_id', itemId)
          .order('created_at', ascending: false);
      return (data as List).map((json) => StockAdjustmentModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch stock adjustments.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<StockAdjustmentModel> create(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.inventoryStockAdjustmentsTable)
          .insert(json)
          .select()
          .single();
      return StockAdjustmentModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create stock adjustment.', code: 'CREATE_FAILED', cause: e);
    }
  }
}
