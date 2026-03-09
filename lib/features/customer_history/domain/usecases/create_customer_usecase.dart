import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class CreateCustomerParams {
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String? location;
  final String? notes;

  const CreateCustomerParams({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.location,
    this.notes,
  });
}

class CreateCustomerUsecase implements UseCase<CustomerEntity, CreateCustomerParams> {
  final CustomerRepository _repository;
  CreateCustomerUsecase(this._repository);

  @override
  Future<CustomerEntity> call(CreateCustomerParams params) async {
    if (params.fullName.trim().length < 2) {
      throw const ValidationException(
        message: 'Customer name must be at least 2 characters.',
        code: 'NAME_TOO_SHORT',
        field: 'full_name',
      );
    }
    if (!PhoneFormatter.isValid(params.phoneNumber)) {
      throw const ValidationException(
        message: 'Please enter a valid phone number.',
        code: 'PHONE_INVALID',
        field: 'phone_number',
      );
    }
    final now = DateTime.now();
    final customer = CustomerEntity(
      id: '',
      userId: params.userId,
      fullName: params.fullName.trim(),
      phoneNumber: PhoneFormatter.normalize(params.phoneNumber),
      location: params.location,
      notes: params.notes,
      totalJobs: 0,
      createdAt: now,
      updatedAt: now,
    );
    return _repository.createCustomer(customer);
  }
}
