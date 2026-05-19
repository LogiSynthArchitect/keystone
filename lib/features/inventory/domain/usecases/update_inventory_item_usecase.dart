import '../../../../core/usecases/use_case.dart';
import '../entities/inventory_item_entity.dart';
import '../repositories/inventory_repository.dart';

class UpdateInventoryItemParams {
  final InventoryItemEntity item;
  const UpdateInventoryItemParams(this.item);
}

class UpdateInventoryItemUsecase implements UseCase<InventoryItemEntity, UpdateInventoryItemParams> {
  final InventoryRepository _repository;
  UpdateInventoryItemUsecase(this._repository);

  @override
  Future<InventoryItemEntity> call(UpdateInventoryItemParams params) {
    return _repository.updateItem(params.item);
  }
}
