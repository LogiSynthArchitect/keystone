import '../../../customer_history/domain/entities/key_code_entry_entity.dart';
import '../repositories/key_code_repository.dart';

class GetKeyCodesUsecase {
  final KeyCodeRepository _repository;
  GetKeyCodesUsecase(this._repository);

  Future<List<KeyCodeEntryEntity>> call(String customerId) =>
      _repository.getKeyCodesForCustomer(customerId);
}
