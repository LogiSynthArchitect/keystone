import 'package:uuid/uuid.dart';
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

  CreateCustomerParams({
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
    final normalizedPhone = PhoneFormatter.normalize(params.phoneNumber);
    
    if (!PhoneFormatter.isValid(params.phoneNumber)) {
      throw const ValidationException(
        message: 'Please enter a valid phone number.',
        code: 'INVALID_PHONE',
        field: 'phone_number',
      );
    }

    // Check if phone number is already taken
    final existingByPhone = await _repository.getCustomerByPhone(normalizedPhone);
    if (existingByPhone != null) {
      throw ValidationException(
        message: 'A customer with this phone number already exists (${existingByPhone.fullName}).',
        code: 'PHONE_EXISTS',
        field: 'phone_number',
      );
    }

    // Check if name is already taken (exact match case-insensitive)
    final searchResult = await _repository.searchCustomers(params.fullName.trim());
    final existingByName = searchResult.any((c) => 
      c.fullName.toLowerCase() == params.fullName.trim().toLowerCase());
    
    if (existingByName) {
      throw ValidationException(
        message: 'A customer named "${params.fullName}" already exists.',
        code: 'NAME_EXISTS',
        field: 'full_name',
      );
    }

    final now = DateTime.now();
    final customer = CustomerEntity(
      id: const Uuid().v4(),
      userId: params.userId,
      fullName: params.fullName.trim(),
      phoneNumber: normalizedPhone,
      location: params.location,
      notes: params.notes,
      totalJobs: 0,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.createCustomer(customer);
  }
}
