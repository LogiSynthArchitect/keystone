import '../../../../core/usecases/use_case.dart';
import '../entities/inventory_item_entity.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryItemsParams {
  final String userId;
  final bool includeArchived;
  const GetInventoryItemsParams(this.userId, {this.includeArchived = false});
}

class GetInventoryItemsUsecase implements UseCase<List<InventoryItemEntity>, GetInventoryItemsParams> {
  final InventoryRepository _repository;
  GetInventoryItemsUsecase(this._repository);

  @override
  Future<List<InventoryItemEntity>> call(GetInventoryItemsParams params) {
    return _repository.getItems(params.userId, includeArchived: params.includeArchived);
  }
}
