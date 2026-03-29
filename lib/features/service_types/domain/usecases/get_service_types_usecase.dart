import '../../../../core/usecases/use_case.dart';
import '../entities/service_type_entity.dart';
import '../repositories/service_type_repository.dart';

class GetServiceTypesUsecase implements UseCase<List<ServiceTypeEntity>, NoParams> {
  final ServiceTypeRepository _repository;
  GetServiceTypesUsecase(this._repository);

  @override
  Future<List<ServiceTypeEntity>> call(NoParams params) {
    return _repository.getServiceTypes();
  }
}
