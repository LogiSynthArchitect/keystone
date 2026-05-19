import '../entities/inventory_item_entity.dart';
import '../entities/stock_adjustment_entity.dart';
import '../entities/restock_entity.dart';

abstract class InventoryRepository {
  Future<List<InventoryItemEntity>> getItems(String userId, {bool includeArchived = false});
  Future<InventoryItemEntity> createItem(InventoryItemEntity item);
  Future<InventoryItemEntity> updateItem(InventoryItemEntity item);
  Future<void> deleteItem(String id);
  Future<void> syncItems(String userId);

  Future<InventoryItemEntity> adjustStock(
    String itemId,
    String userId,
    int quantityChange,
    String adjustmentType, {
    String? reason,
    String? referenceType,
    String? referenceId,
  });

  Future<InventoryItemEntity> restockItem({
    required String itemId,
    required String userId,
    required int quantity,
    required int unitCost,
    String? vendor,
    String? supplierPhone,
    String? notes,
  });

  Future<List<StockAdjustmentEntity>> getStockAdjustments(String itemId);
  Future<List<RestockEntity>> getRestocks(String itemId);
}
