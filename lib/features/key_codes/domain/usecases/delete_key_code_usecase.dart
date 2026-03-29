import '../repositories/key_code_repository.dart';

class DeleteKeyCodeUsecase {
  final KeyCodeRepository _repository;
  DeleteKeyCodeUsecase(this._repository);

  Future<void> call(String id) => _repository.deleteKeyCode(id);
}
