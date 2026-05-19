import '../../../../core/usecases/use_case.dart';
import '../repositories/inventory_repository.dart';

class DeleteInventoryItemParams {
  final String id;
  const DeleteInventoryItemParams(this.id);
}

class DeleteInventoryItemUsecase implements UseCase<void, DeleteInventoryItemParams> {
  final InventoryRepository _repository;
  DeleteInventoryItemUsecase(this._repository);

  @override
  Future<void> call(DeleteInventoryItemParams params) {
    return _repository.deleteItem(params.id);
  }
}
