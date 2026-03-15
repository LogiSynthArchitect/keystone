import '../../../../core/usecases/use_case.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetCustomerByPhoneUsecase implements UseCase<CustomerEntity?, String> {
  final CustomerRepository _repository;
  GetCustomerByPhoneUsecase(this._repository);

  @override
  Future<CustomerEntity?> call(String phoneNumber) async {
    return await _repository.getCustomerByPhone(phoneNumber);
  }
}
