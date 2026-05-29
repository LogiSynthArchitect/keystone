import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/storage/hive_service.dart';
import '../datasources/inventory_local_datasource.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../datasources/inventory_stock_adjustments_local_datasource.dart';
import '../datasources/inventory_stock_adjustments_remote_datasource.dart';
import '../datasources/inventory_restocks_local_datasource.dart';
import '../datasources/inventory_restocks_remote_datasource.dart';
import '../models/inventory_item_model.dart';
import '../models/stock_adjustment_model.dart';
import '../models/restock_model.dart';
import '../models/pending_restock_wal.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/stock_adjustment_entity.dart';
import '../../domain/entities/restock_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../../core/constants/app_enums.dart';

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
    var localModels = await _local.getAll(includeArchived: includeArchived);
    // Backfill searchIndex for existing items that lack it
    bool anyBackfilled = false;
    for (final model in localModels) {
      if (model.searchIndex == null) {
        final index = _buildSearchIndex(model);
        if (index != null) {
          await _local.saveItem(model.copyWith(searchIndex: index));
          anyBackfilled = true;
        }
      }
    }
    if (anyBackfilled) {
      localModels = await _local.getAll(includeArchived: includeArchived);
    }
    return localModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<InventoryItemEntity> createItem(InventoryItemEntity item) async {
    final indexed = item.copyWith(
      syncStatus: SyncStatus.pending,
      searchIndex: InventoryItemEntity.buildSearchIndex(
        name: item.name,
        brand: item.brand,
        model: item.model,
        location: item.location,
        keySpec: item.keySpec,
        material: item.material,
        finish: item.finish,
        dimensions: item.dimensions,
        category: item.category,
        attributes: item.attributes,
      ),
    );
    final model = InventoryItemModel.fromEntity(indexed);
    await _local.saveItem(model);
    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.create(model.toJson());
        final synced = remoteModel.toEntity().copyWith(syncStatus: SyncStatus.synced);
        await _local.saveItem(InventoryItemModel.fromEntity(synced));
        return synced;
      } catch (e) {
        debugPrint('[KS:INVENTORY] Remote create failed: $e');
      }
    }
    return indexed;
  }

  @override
  Future<InventoryItemEntity> updateItem(InventoryItemEntity item) async {
    final indexed = item.copyWith(
      syncStatus: SyncStatus.pending,
      searchIndex: InventoryItemEntity.buildSearchIndex(
        name: item.name,
        brand: item.brand,
        model: item.model,
        location: item.location,
        keySpec: item.keySpec,
        material: item.material,
        finish: item.finish,
        dimensions: item.dimensions,
        category: item.category,
        attributes: item.attributes,
      ),
    );
    final model = InventoryItemModel.fromEntity(indexed);
    await _local.saveItem(model);
    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.update(item.id, model.toJson());
        final synced = remoteModel.toEntity().copyWith(syncStatus: SyncStatus.synced);
        await _local.saveItem(InventoryItemModel.fromEntity(synced));
        return synced;
      } catch (e) {
        debugPrint('[KS:INVENTORY] Remote update failed: $e');
      }
    }
    return indexed;
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
      // PHASE 1: PUSH pending items to server (UPSERT — insert if new, update if exists)
      final localItems = await _local.getAll(includeArchived: true);
      final pendingItems = localItems.where((m) => m.syncStatus == SyncStatus.pending).toList();
      for (final item in pendingItems) {
        try {
          final remote = await _remote.upsert(item.toJson());
          final synced = remote.toEntity().copyWith(syncStatus: SyncStatus.synced);
          await _local.saveItem(InventoryItemModel.fromEntity(synced));
        } catch (e) {
          debugPrint('[KS:INVENTORY] PUSH failed for item ${item.id}: $e');
        }
      }

      // PHASE 2: PULL remote items and diff-merge (respect correction_fields)
      final remoteModels = await _remote.getAll(userId);
      final localByUuid = {for (final m in localItems) m.id: m};

      for (final remote in remoteModels) {
        final existing = localByUuid[remote.id];

        // Tombstone handler: remote is_deleted → hard-delete from local
        if (remote.isDeleted) {
          if (existing != null) {
            await _local.deleteItem(remote.id);
          }
          continue;
        }

        if (existing == null) {
          // New remote item — save locally
          await _local.saveItem(remote);
        } else if (existing.syncStatus == SyncStatus.pending) {
          // Local has pending edits — keep local (PUSH already sent it to server)
          continue;
        } else if (remote.correctionFields.isNotEmpty && existing.syncStatus == SyncStatus.synced) {
          // Admin has locked certain fields — merge field-by-field
          final merged = _mergeWithCorrections(existing, remote);
          await _local.saveItem(merged);
        } else {
          // No local edits and no locks — overwrite with remote
          await _local.saveItem(remote);
        }
      }
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
    String? transactionId,
  }) async {
    final existing = await _local.getById(itemId);
    if (existing == null) throw Exception('Item not found.');

    // Idempotency guard: if this transaction was already applied, skip
    if (transactionId != null && existing.appliedTransactionIds.contains(transactionId)) {
      debugPrint('[KS:INVENTORY] Skipping already-applied transaction $transactionId on item $itemId');
      return existing.toEntity();
    }

    final updatedAppliedIds = transactionId != null
        ? [...existing.appliedTransactionIds, transactionId]
        : existing.appliedTransactionIds;

    final newQuantity = (existing.quantity + quantityChange).clamp(0, 999999);

    // P0-3b: For manual_add, recalculate weighted-average cost using current
    // defaultCostPrice as the implied unit cost — prevents silent dilution
    // when quantity increases without an explicit cost entry.
    final int? updatedCostPrice;
    if (adjustmentType == 'manual_add' && quantityChange > 0 && existing.defaultCostPrice != null) {
      final oldQty = existing.quantity;
      final oldCost = existing.defaultCostPrice!;
      final totQty = oldQty + quantityChange;
      updatedCostPrice = ((oldQty * oldCost) + (quantityChange * oldCost)) ~/ totQty;
    } else {
      updatedCostPrice = null;
    }

    final updatedItem = existing.toEntity().copyWith(
      quantity: newQuantity,
      defaultCostPrice: updatedCostPrice,
      appliedTransactionIds: updatedAppliedIds,
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

    // Fetch current item for weighted average cost calculation
    final existing = await _local.getById(itemId);
    final oldQty = existing?.quantity ?? 0;
    final oldCost = existing?.defaultCostPrice ?? 0;

    // Weighted average cost: (old_qty × old_cost + new_qty × new_cost) / total_qty
    final newQty = oldQty + quantity;
    final int newAvgCost;
    if (oldQty == 0 || oldCost == 0) {
      newAvgCost = unitCost;
    } else {
      newAvgCost = ((oldQty * oldCost) + (quantity * unitCost)) ~/ newQty;
    }

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

    // P0-3c: Write-Ahead Log — persist to _meta before any mutations
    final wal = PendingRestockWal(
      restockId: restock.id,
      itemId: itemId,
      quantityDelta: quantity,
      unitCost: unitCost,
      previousCost: oldCost,
      previousQty: oldQty,
      createdAt: DateTime.now(),
    );
    final metaKey = 'pending_restock:${restock.id}';
    final metaBox = Hive.box(HiveService.metaBox);
    await metaBox.put(metaKey, wal.toJson());
    await metaBox.flush();
    debugPrint('[KS:INVENTORY] WAL written: $metaKey');

    late final InventoryItemEntity result;
    try {
      await _restockLocal.save(restock);

      final updated = await adjustStock(
        itemId, userId, quantity, 'restock',
        referenceType: 'restock',
        referenceId: restock.id,
        transactionId: restock.id, // prevent double-apply on crash recovery
      );

      // Update the item's defaultCostPrice to the new weighted average
      result = updated.copyWith(
        defaultCostPrice: newAvgCost,
        updatedAt: DateTime.now(),
      );
      await updateItem(result);

      // All mutations succeeded — clear the WAL
      await metaBox.delete(metaKey);
      await metaBox.flush();
      debugPrint('[KS:INVENTORY] WAL cleared: $metaKey');
    } catch (e) {
      debugPrint('[KS:INVENTORY] Restock failed, WAL preserved for recovery: $e');
      rethrow;
    }

    if (await _connectivity.isConnected) {
      try {
        await _restockRemote.create(restock.toJson());
      } catch (e) {
        debugPrint('[KS:INVENTORY] Remote restock save failed: $e');
      }
    }

    return result;
  }

  /// Build a search index from model fields for backfill.
  String? _buildSearchIndex(InventoryItemModel model) =>
      InventoryItemEntity.buildSearchIndex(
        name: model.name,
        brand: model.brand,
        model: model.model,
        location: model.location,
        keySpec: model.keySpec,
        material: model.material,
        finish: model.finish,
        dimensions: model.dimensions,
        category: model.category,
        attributes: model.attributes,
      );

  /// Merge remote into local, respecting admin-locked [correctionFields].
  /// Locked fields: keep local value. Unlocked fields: accept remote value.
  InventoryItemModel _mergeWithCorrections(InventoryItemModel local, InventoryItemModel remote) {
    final locked = Set<String>.from(remote.correctionFields);
    return InventoryItemModel(
      id: remote.id,
      userId: remote.userId,
      category: locked.contains('item_type') ? local.category : remote.category,
      name: locked.contains('name') ? local.name : remote.name,
      attributes: locked.contains('attributes') ? local.attributes : remote.attributes,
      brand: locked.contains('brand') ? local.brand : remote.brand,
      model: locked.contains('model') ? local.model : remote.model,
      keySpec: locked.contains('key_spec') ? local.keySpec : remote.keySpec,
      material: locked.contains('material') ? local.material : remote.material,
      finish: locked.contains('finish') ? local.finish : remote.finish,
      dimensions: locked.contains('dimensions') ? local.dimensions : remote.dimensions,
      defaultCostPrice: locked.contains('default_cost_price') ? local.defaultCostPrice : remote.defaultCostPrice,
      defaultSalePrice: locked.contains('default_sale_price') ? local.defaultSalePrice : remote.defaultSalePrice,
      quantity: locked.contains('quantity') ? local.quantity : remote.quantity,
      lowStockThreshold: locked.contains('low_stock_threshold') ? local.lowStockThreshold : remote.lowStockThreshold,
      location: locked.contains('location') ? local.location : remote.location,
      isArchived: locked.contains('is_archived') ? local.isArchived : remote.isArchived,
      isAutoCogs: locked.contains('is_auto_cogs') ? local.isAutoCogs : remote.isAutoCogs,
      snoozeLowStockUntil: locked.contains('snooze_low_stock_until') ? local.snoozeLowStockUntil : remote.snoozeLowStockUntil,
      coverImageUrl: locked.contains('cover_image_url') ? local.coverImageUrl : remote.coverImageUrl,
      appliedTransactionIds: remote.appliedTransactionIds,
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      syncStatus: SyncStatus.synced,
      correctionFields: const [],
      updatedBy: remote.updatedBy,
      searchIndex: remote.searchIndex ?? local.searchIndex,
    );
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
