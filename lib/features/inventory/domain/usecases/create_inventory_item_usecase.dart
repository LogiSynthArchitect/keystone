import '../../../../core/usecases/use_case.dart';
import '../entities/inventory_item_entity.dart';
import '../repositories/inventory_repository.dart';

class CreateInventoryItemParams {
  final InventoryItemEntity item;
  const CreateInventoryItemParams(this.item);
}

class CreateInventoryItemUsecase implements UseCase<InventoryItemEntity, CreateInventoryItemParams> {
  final InventoryRepository _repository;
  CreateInventoryItemUsecase(this._repository);

  @override
  Future<InventoryItemEntity> call(CreateInventoryItemParams params) {
    return _repository.createItem(params.item);
  }
}
