import '../../../../core/usecases/use_case.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetCustomerUsecase implements UseCase<CustomerEntity, String> {
  final CustomerRepository _repository;
  GetCustomerUsecase(this._repository);

  @override
  Future<CustomerEntity> call(String id) => _repository.getCustomerById(id);
}
