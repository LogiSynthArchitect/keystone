import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/inventory_item_model.dart';

class InventoryLocalDatasource {
  Box get _box => HiveService.inventoryItems;

  Future<List<InventoryItemModel>> getAll({bool includeArchived = false}) async {
    var items = _box.values
        .map((json) => InventoryItemModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    if (!includeArchived) {
      items = items.where((i) => !i.isArchived).toList();
    }
    return items;
  }

  Future<InventoryItemModel?> getById(String id) async {
    final json = _box.get(id);
    if (json == null) return null;
    return InventoryItemModel.fromJson(Map<String, dynamic>.from(json));
  }

  Future<void> saveItem(InventoryItemModel model) async {
    await _box.put(model.id, model.toJson());
    await _box.flush();
  }

  Future<void> saveAll(List<InventoryItemModel> models) async {
    final Map<String, Map> map = {
      for (var m in models) m.id: m.toJson(),
    };
    await _box.putAll(map);
    await _box.flush();
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Future<void> clear() async {
    await _box.clear();
    await _box.flush();
  }
}
