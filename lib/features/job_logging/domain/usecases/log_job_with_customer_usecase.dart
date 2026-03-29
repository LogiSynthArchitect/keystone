import '../../../../core/errors/validation_exception.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../customer_history/domain/repositories/customer_repository.dart';
import '../../../customer_history/domain/usecases/create_customer_usecase.dart';
import '../entities/job_entity.dart';
import 'log_job_usecase.dart';

class LogJobWithCustomerParams {
  final String userId;
  final String serviceType;
  final DateTime jobDate;
  final String? existingCustomerId;
  final String? newCustomerName;
  final String? customerPhone;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final int? amountCharged;
  final String status;
  final String paymentStatus;
  final double? quotedPrice;
  final String? hardwareBrand;
  final String? hardwareKeyway;

  const LogJobWithCustomerParams({
    required this.userId,
    required this.serviceType,
    required this.jobDate,
    this.existingCustomerId,
    this.newCustomerName,
    this.customerPhone,
    this.location,
    this.latitude,
    this.longitude,
    this.notes,
    this.amountCharged,
    this.status = 'in_progress',
    this.paymentStatus = 'unpaid',
    this.quotedPrice,
    this.hardwareBrand,
    this.hardwareKeyway,
  });
}

class LogJobWithCustomerUsecase {
  final LogJobUsecase _logJob;
  final CreateCustomerUsecase _createCustomer;
  final CustomerRepository _customerRepo;

  LogJobWithCustomerUsecase(this._logJob, this._createCustomer, this._customerRepo);

  Future<JobEntity> call(LogJobWithCustomerParams params) async {
    String finalCustomerId;
    String? createdCustomerId;

    try {
      if (params.existingCustomerId != null) {
        finalCustomerId = params.existingCustomerId!;
      } else if (params.newCustomerName != null && params.customerPhone != null) {
        final normalized = PhoneFormatter.normalize(params.customerPhone!);
        final existing = await _customerRepo.getCustomerByPhone(normalized);
        
        if (existing != null) {
          finalCustomerId = existing.id;
        } else {
          final customer = await _createCustomer(CreateCustomerParams(
            userId: params.userId,
            fullName: params.newCustomerName!,
            phoneNumber: normalized,
            location: params.location,
          ));
          finalCustomerId = customer.id;
          createdCustomerId = customer.id;
        }
      } else {
        throw const ValidationException(
          message: 'Customer identification missing.',
          code: 'MISSING_CUSTOMER',
        );
      }

      return await _logJob(LogJobParams(
        userId: params.userId,
        customerId: finalCustomerId,
        serviceType: params.serviceType,
        jobDate: params.jobDate,
        location: params.location,
        latitude: params.latitude,
        longitude: params.longitude,
        notes: params.notes,
        amountCharged: params.amountCharged,
        status: params.status,
        paymentStatus: params.paymentStatus,
        quotedPrice: params.quotedPrice,
        hardwareBrand: params.hardwareBrand,
        hardwareKeyway: params.hardwareKeyway,
      ));
    } catch (e) {
      if (createdCustomerId != null) {
        await _customerRepo.deleteCustomer(createdCustomerId);
      }
      rethrow;
    }
  }
}
