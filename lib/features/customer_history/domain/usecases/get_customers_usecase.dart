import '../../../../core/usecases/use_case.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetCustomersUsecase implements NoParamsUseCase<List<CustomerEntity>> {
  final CustomerRepository _repository;
  GetCustomersUsecase(this._repository);

  @override
  Future<List<CustomerEntity>> call() => _repository.getCustomers();
}
