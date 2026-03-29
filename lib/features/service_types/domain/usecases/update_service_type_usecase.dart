import '../../../../core/usecases/use_case.dart';
import '../entities/service_type_entity.dart';
import '../repositories/service_type_repository.dart';

class UpdateServiceTypeParams {
  final ServiceTypeEntity serviceType;
  const UpdateServiceTypeParams(this.serviceType);
}

class UpdateServiceTypeUsecase implements UseCase<ServiceTypeEntity, UpdateServiceTypeParams> {
  final ServiceTypeRepository _repository;
  UpdateServiceTypeUsecase(this._repository);

  @override
  Future<ServiceTypeEntity> call(UpdateServiceTypeParams params) {
    return _repository.updateServiceType(params.serviceType);
  }
}
