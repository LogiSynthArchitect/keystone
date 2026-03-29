import 'package:uuid/uuid.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/service_type_entity.dart';
import '../repositories/service_type_repository.dart';

class SeedDefaultServiceTypesUseCase implements UseCase<void, String> {
  final ServiceTypeRepository _repository;
  SeedDefaultServiceTypesUseCase(this._repository);

  @override
  Future<void> call(String userId) async {
    final now = DateTime.now();
    final defaults = [
      ServiceTypeEntity(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Car Key Programming',
        createdAt: now,
        updatedAt: now,
      ),
      ServiceTypeEntity(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Door Lock Installation',
        createdAt: now,
        updatedAt: now,
      ),
      ServiceTypeEntity(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Door Lock Repair',
        createdAt: now,
        updatedAt: now,
      ),
      ServiceTypeEntity(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Smart Lock Installation',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final service in defaults) {
      await _repository.createServiceType(service);
    }
  }
}
