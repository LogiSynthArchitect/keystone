import '../../../../core/usecases/use_case.dart';
import '../repositories/service_type_repository.dart';

class DeleteServiceTypeUsecase implements UseCase<void, String> {
  final ServiceTypeRepository _repository;
  DeleteServiceTypeUsecase(this._repository);

  @override
  Future<void> call(String id) {
    return _repository.deleteServiceType(id);
  }
}
