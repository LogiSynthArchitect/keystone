import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/stock_adjustment_model.dart';

class InventoryStockAdjustmentsLocalDatasource {
  Box get _box => HiveService.inventoryStockAdjustments;

  Future<List<StockAdjustmentModel>> getForItem(String itemId) async {
    return _box.values
        .map((json) => StockAdjustmentModel.fromJson(Map<String, dynamic>.from(json)))
        .where((a) => a.itemId == itemId)
        .toList();
  }

  Future<void> save(StockAdjustmentModel model) async {
    await _box.put(model.id, model.toJson());
    await _box.flush();
  }

  Future<void> saveAll(List<StockAdjustmentModel> models) async {
    final map = {for (var m in models) m.id: m.toJson()};
    await _box.putAll(map);
    await _box.flush();
  }

  Future<void> deleteForItem(String itemId) async {
    final keys = _box.values
        .where((j) => j['item_id'] == itemId)
        .map((j) => j['id'] as String)
        .toList();
    await _box.deleteAll(keys);
    await _box.flush();
  }
}
