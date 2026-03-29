import 'package:uuid/uuid.dart';
import '../../../customer_history/domain/entities/key_code_entry_entity.dart';
import '../repositories/key_code_repository.dart';

class CreateKeyCodeParams {
  final String customerId;
  final String? jobId;
  final String keyCode;
  final String? keyType;
  final String? bitting;
  final String? description;

  const CreateKeyCodeParams({
    required this.customerId,
    this.jobId,
    required this.keyCode,
    this.keyType,
    this.bitting,
    this.description,
  });
}

class CreateKeyCodeUsecase {
  final KeyCodeRepository _repository;
  CreateKeyCodeUsecase(this._repository);

  Future<KeyCodeEntryEntity> call(CreateKeyCodeParams params) {
    final now = DateTime.now();
    final entry = KeyCodeEntryEntity(
      id: const Uuid().v4(),
      customerId: params.customerId,
      jobId: params.jobId,
      keyCode: params.keyCode,
      keyType: params.keyType,
      bitting: params.bitting,
      description: params.description,
      createdAt: now,
      updatedAt: now,
    );
    return _repository.createKeyCode(entry);
  }
}
