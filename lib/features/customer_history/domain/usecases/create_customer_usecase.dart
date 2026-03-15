import 'package:uuid/uuid.dart';
import '../../../../core/usecases/use_case.dart';
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
    // Task 1: Identity Conflict Fix - Check for existing phone number before creating
    final existing = await _repository.getCustomerByPhone(params.phoneNumber);
    if (existing != null) {
      return existing; // Return the original record to preserve history identity
    }

    final now = DateTime.now();
    final customer = CustomerEntity(
      id: const Uuid().v4(),
      userId: params.userId,
      fullName: params.fullName,
      phoneNumber: params.phoneNumber,
      location: params.location,
      notes: params.notes,
      totalJobs: 0,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.createCustomer(customer);
  }
}
