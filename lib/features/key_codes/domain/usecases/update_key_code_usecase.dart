import '../../../customer_history/domain/entities/key_code_entry_entity.dart';
import '../repositories/key_code_repository.dart';

class UpdateKeyCodeUsecase {
  final KeyCodeRepository _repository;
  UpdateKeyCodeUsecase(this._repository);

  Future<KeyCodeEntryEntity> call(KeyCodeEntryEntity entry) =>
      _repository.updateKeyCode(entry.copyWith(updatedAt: DateTime.now()));
}
