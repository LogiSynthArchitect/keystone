import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../data/datasources/inventory_local_datasource.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/datasources/inventory_stock_adjustments_local_datasource.dart';
import '../../data/datasources/inventory_stock_adjustments_remote_datasource.dart';
import '../../data/datasources/inventory_restocks_local_datasource.dart';
import '../../data/datasources/inventory_restocks_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/stock_adjustment_entity.dart';
import '../../domain/entities/restock_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/usecases/get_inventory_items_usecase.dart';
import '../../domain/usecases/create_inventory_item_usecase.dart';
import '../../domain/usecases/update_inventory_item_usecase.dart';
import '../../domain/usecases/delete_inventory_item_usecase.dart';

final inventoryLocalDatasourceProvider = Provider<InventoryLocalDatasource>((ref) => InventoryLocalDatasource());
final inventoryRemoteDatasourceProvider = Provider<InventoryRemoteDatasource>((ref) => InventoryRemoteDatasource(ref.watch(supabaseClientProvider)));
final inventoryAdjLocalDatasourceProvider = Provider<InventoryStockAdjustmentsLocalDatasource>((ref) => InventoryStockAdjustmentsLocalDatasource());
final inventoryAdjRemoteDatasourceProvider = Provider<InventoryStockAdjustmentsRemoteDatasource>((ref) => InventoryStockAdjustmentsRemoteDatasource(ref.watch(supabaseClientProvider)));
final inventoryRestockLocalDatasourceProvider = Provider<InventoryRestocksLocalDatasource>((ref) => InventoryRestocksLocalDatasource());
final inventoryRestockRemoteDatasourceProvider = Provider<InventoryRestocksRemoteDatasource>((ref) => InventoryRestocksRemoteDatasource(ref.watch(supabaseClientProvider)));

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) => InventoryRepositoryImpl(
  ref.watch(inventoryRemoteDatasourceProvider),
  ref.watch(inventoryLocalDatasourceProvider),
  ref.watch(connectivityServiceProvider),
  ref.watch(inventoryAdjLocalDatasourceProvider),
  ref.watch(inventoryAdjRemoteDatasourceProvider),
  ref.watch(inventoryRestockLocalDatasourceProvider),
  ref.watch(inventoryRestockRemoteDatasourceProvider),
));

final getInventoryItemsUsecaseProvider = Provider<GetInventoryItemsUsecase>((ref) => GetInventoryItemsUsecase(ref.watch(inventoryRepositoryProvider)));
final createInventoryItemUsecaseProvider = Provider<CreateInventoryItemUsecase>((ref) => CreateInventoryItemUsecase(ref.watch(inventoryRepositoryProvider)));
final updateInventoryItemUsecaseProvider = Provider<UpdateInventoryItemUsecase>((ref) => UpdateInventoryItemUsecase(ref.watch(inventoryRepositoryProvider)));
final deleteInventoryItemUsecaseProvider = Provider<DeleteInventoryItemUsecase>((ref) => DeleteInventoryItemUsecase(ref.watch(inventoryRepositoryProvider)));

class InventoryNotifier extends StateNotifier<AsyncValue<List<InventoryItemEntity>>> {
  final Ref _ref;
  InventoryNotifier(this._ref) : super(const AsyncValue.loading());

  String? _userId;

  Future<void> loadItems(String userId, {bool includeArchived = false}) async {
    _userId = userId;
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(inventoryRepositoryProvider);
      final items = await repo.getItems(userId, includeArchived: includeArchived);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem({
    required InventoryItemCategory category,
    required String name,
    Map<String, dynamic> attributes = const {},
    String? brand,
    String? model,
    String? keySpec,
    String? material,
    String? finish,
    String? dimensions,
    int? defaultCostPrice,
    int? defaultSalePrice,
    int quantity = 0,
    int? lowStockThreshold,
    String? location,
    bool isAutoCogs = false,
    String? coverImageUrl,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final item = InventoryItemEntity(
        id: const Uuid().v4(),
        userId: userId,
        category: category,
        name: name,
        attributes: attributes,
        brand: brand,
        model: model,
        keySpec: keySpec,
        material: material,
        finish: finish,
        dimensions: dimensions,
        defaultCostPrice: defaultCostPrice,
        defaultSalePrice: defaultSalePrice,
        quantity: quantity,
        lowStockThreshold: lowStockThreshold,
        location: location,
        isAutoCogs: isAutoCogs,
        coverImageUrl: coverImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _ref.read(createInventoryItemUsecaseProvider).call(CreateInventoryItemParams(item));
      await loadItems(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateItem(InventoryItemEntity item) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final updated = item.copyWith(updatedAt: DateTime.now());
      await _ref.read(updateInventoryItemUsecaseProvider).call(UpdateInventoryItemParams(updated));
      await loadItems(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteItem(String id) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _ref.read(deleteInventoryItemUsecaseProvider).call(DeleteInventoryItemParams(id));
      await loadItems(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> archiveItem(String id) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final repo = _ref.read(inventoryRepositoryProvider);
      final items = state.maybeWhen(data: (d) => d, orElse: () => <InventoryItemEntity>[]);
      final item = items.firstWhere((i) => i.id == id);
      await repo.updateItem(item.copyWith(isArchived: true, updatedAt: DateTime.now()));
      await loadItems(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unarchiveItem(String id) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final repo = _ref.read(inventoryRepositoryProvider);
      final items = await repo.getItems(userId, includeArchived: true);
      final item = items.firstWhere((i) => i.id == id);
      await repo.updateItem(item.copyWith(isArchived: false, updatedAt: DateTime.now()));
      await loadItems(userId, includeArchived: true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> adjustStock({
    required String itemId,
    required int quantityChange,
    required String adjustmentType,
    String? reason,
    String? referenceType,
    String? referenceId,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final repo = _ref.read(inventoryRepositoryProvider);
      await repo.adjustStock(
        itemId, userId, quantityChange, adjustmentType,
        reason: reason, referenceType: referenceType, referenceId: referenceId,
      );
      await loadItems(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restockItem({
    required String itemId,
    required int quantity,
    required int unitCost,
    String? vendor,
    String? supplierPhone,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final repo = _ref.read(inventoryRepositoryProvider);
      await repo.restockItem(
        itemId: itemId,
        userId: userId,
        quantity: quantity,
        unitCost: unitCost,
        vendor: vendor,
        supplierPhone: supplierPhone,
        notes: notes,
      );
      await loadItems(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<StockAdjustmentEntity>> getStockAdjustments(String itemId) async {
    try {
      final repo = _ref.read(inventoryRepositoryProvider);
      return await repo.getStockAdjustments(itemId);
    } catch (_) {
      return [];
    }
  }

  Future<List<RestockEntity>> getRestocks(String itemId) async {
    try {
      final repo = _ref.read(inventoryRepositoryProvider);
      return await repo.getRestocks(itemId);
    } catch (_) {
      return [];
    }
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, AsyncValue<List<InventoryItemEntity>>>((ref) {
  return InventoryNotifier(ref);
});
