import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerParams {
  final CustomerEntity customer;

  UpdateCustomerParams({required this.customer});
}

class UpdateCustomerUsecase implements UseCase<CustomerEntity, UpdateCustomerParams> {
  final CustomerRepository _repository;
  UpdateCustomerUsecase(this._repository);

  @override
  Future<CustomerEntity> call(UpdateCustomerParams params) async {
    final customer = params.customer;
    
    // Basic phone validation
    final cleanPhone = customer.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) {
      throw const ValidationException(
        message: 'Phone number must have at least 10 digits.',
        code: 'PHONE_TOO_SHORT',
        field: 'phone_number',
      );
    }

    final updatedCustomer = customer.copyWith(
      updatedAt: DateTime.now(),
    );

    return _repository.updateCustomer(updatedCustomer);
  }
}
