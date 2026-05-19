import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import '../datasources/inventory_local_datasource.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../datasources/inventory_stock_adjustments_local_datasource.dart';
import '../datasources/inventory_stock_adjustments_remote_datasource.dart';
import '../datasources/inventory_restocks_local_datasource.dart';
import '../datasources/inventory_restocks_remote_datasource.dart';
import '../models/inventory_item_model.dart';
import '../models/stock_adjustment_model.dart';
import '../models/restock_model.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/stock_adjustment_entity.dart';
import '../../domain/entities/restock_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDatasource _remote;
  final InventoryLocalDatasource _local;
  final ConnectivityService _connectivity;
  final InventoryStockAdjustmentsLocalDatasource _adjLocal;
  final InventoryStockAdjustmentsRemoteDatasource _adjRemote;
  final InventoryRestocksLocalDatasource _restockLocal;
  final InventoryRestocksRemoteDatasource _restockRemote;

  InventoryRepositoryImpl(
    this._remote,
    this._local,
    this._connectivity,
    this._adjLocal,
    this._adjRemote,
    this._restockLocal,
    this._restockRemote,
  );

  @override
  Future<List<InventoryItemEntity>> getItems(String userId, {bool includeArchived = false}) async {
    if (await _connectivity.isConnected) {
      await syncItems(userId);
    }
    final localModels = await _local.getAll(includeArchived: includeArchived);
    return localModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<InventoryItemEntity> createItem(InventoryItemEntity item) async {
    final model = InventoryItemModel.fromEntity(item);
    await _local.saveItem(model);
    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.create(model.toJson());
        await _local.saveItem(remoteModel);
        return remoteModel.toEntity();
      } catch (e) {
        debugPrint('[KS:INVENTORY] Remote create failed: $e');
      }
    }
    return model.toEntity();
  }

  @override
  Future<InventoryItemEntity> updateItem(InventoryItemEntity item) async {
    final model = InventoryItemModel.fromEntity(item);
    await _local.saveItem(model);
    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.update(item.id, model.toJson());
        await _local.saveItem(remoteModel);
        return remoteModel.toEntity();
      } catch (e) {
        debugPrint('[KS:INVENTORY] Remote update failed: $e');
      }
    }
    return model.toEntity();
  }

  @override
  Future<void> deleteItem(String id) async {
    await _local.deleteItem(id);
    if (await _connectivity.isConnected) {
      try {
        await _remote.delete(id);
      } catch (e) {
        debugPrint('[KS:INVENTORY] Remote delete failed: $e');
      }
    }
  }

  @override
  Future<void> syncItems(String userId) async {
    try {
      final remoteModels = await _remote.getAll(userId);
      await _local.clear();
      await _local.saveAll(remoteModels);
    } catch (e) {
      debugPrint('[KS:INVENTORY] Sync failed: $e');
    }
  }

  // --- Stock Adjustment ---

  @override
  Future<InventoryItemEntity> adjustStock(
    String itemId,
    String userId,
    int quantityChange,
    String adjustmentType, {
    String? reason,
    String? referenceType,
    String? referenceId,
  }) async {
    final existing = await _local.getById(itemId);
    if (existing == null) throw Exception('Item not found.');

    final newQuantity = (existing.quantity + quantityChange).clamp(0, 999999);
    final updatedItem = existing.toEntity().copyWith(
      quantity: newQuantity,
      updatedAt: DateTime.now(),
    );
    await updateItem(updatedItem);

    final adj = StockAdjustmentModel(
      id: const Uuid().v4(),
      itemId: itemId,
      userId: userId,
      adjustmentType: adjustmentType,
      quantityChange: quantityChange,
      quantityAfter: newQuantity,
      reason: reason,
      referenceType: referenceType,
      referenceId: referenceId,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _adjLocal.save(adj);

    if (await _connectivity.isConnected) {
      try {
        await _adjRemote.create(adj.toJson());
      } catch (e) {
        debugPrint('[KS:INVENTORY] Remote adjustment save failed: $e');
      }
    }

    return updatedItem;
  }

  // --- Restock ---

  @override
  Future<InventoryItemEntity> restockItem({
    required String itemId,
    required String userId,
    required int quantity,
    required int unitCost,
    String? vendor,
    String? supplierPhone,
    String? notes,
  }) async {
    final totalCost = quantity * unitCost;

    final restock = RestockModel(
      id: const Uuid().v4(),
      itemId: itemId,
      userId: userId,
      quantity: quantity,
      unitCost: unitCost,
      totalCost: totalCost,
      vendor: vendor,
      supplierPhone: supplierPhone,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _restockLocal.save(restock);

    final updated = await adjustStock(
      itemId, userId, quantity, 'restock',
      referenceType: 'restock',
      referenceId: restock.id,
    );

    if (await _connectivity.isConnected) {
      try {
        await _restockRemote.create(restock.toJson());
      } catch (e) {
        debugPrint('[KS:INVENTORY] Remote restock save failed: $e');
      }
    }

    return updated;
  }

  @override
  Future<List<StockAdjustmentEntity>> getStockAdjustments(String itemId) async {
    final models = await _adjLocal.getForItem(itemId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<RestockEntity>> getRestocks(String itemId) async {
    final models = await _restockLocal.getForItem(itemId);
    return models.map((m) => m.toEntity()).toList();
  }
}
