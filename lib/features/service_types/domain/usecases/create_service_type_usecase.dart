import 'package:uuid/uuid.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/service_type_entity.dart';
import '../repositories/service_type_repository.dart';

class CreateServiceTypeParams {
  final String userId;
  final String name;
  const CreateServiceTypeParams({required this.userId, required this.name});
}

class CreateServiceTypeUsecase implements UseCase<ServiceTypeEntity, CreateServiceTypeParams> {
  final ServiceTypeRepository _repository;
  CreateServiceTypeUsecase(this._repository);

  @override
  Future<ServiceTypeEntity> call(CreateServiceTypeParams params) {
    final now = DateTime.now();
    final service = ServiceTypeEntity(
      id: const Uuid().v4(),
      userId: params.userId,
      name: params.name,
      createdAt: now,
      updatedAt: now,
    );
    return _repository.createServiceType(service);
  }
}
