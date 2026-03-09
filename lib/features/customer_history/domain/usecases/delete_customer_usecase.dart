import '../../../../core/usecases/use_case.dart';
import '../repositories/customer_repository.dart';

class DeleteCustomerUsecase implements UseCase<void, String> {
  final CustomerRepository _repository;
  DeleteCustomerUsecase(this._repository);

  @override
  Future<void> call(String id) => _repository.deleteCustomer(id);
}
