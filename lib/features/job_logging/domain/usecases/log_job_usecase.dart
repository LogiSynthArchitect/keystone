import 'package:uuid/uuid.dart';
import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/job_entity.dart';
import '../repositories/job_repository.dart';
import '../../../customer_history/domain/repositories/customer_repository.dart';
import '../../../../core/constants/app_enums.dart';

class LogJobParams {
  final String userId;
  final String customerId;
  final String serviceType;
  final DateTime jobDate;
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

  const LogJobParams({
    required this.userId,
    required this.customerId,
    required this.serviceType,
    required this.jobDate,
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

class LogJobUsecase implements UseCase<JobEntity, LogJobParams> {
  final JobRepository _repository;
  final CustomerRepository _customerRepository;
  
  LogJobUsecase(this._repository, this._customerRepository);

  @override
  Future<JobEntity> call(LogJobParams params) async {
    // Relationship validation: Verify Customer exists
    try {
      await _customerRepository.getCustomerById(params.customerId);
    } catch (e) {
      throw const ValidationException(
        message: 'The selected customer no longer exists.',
        code: 'CUSTOMER_NOT_FOUND',
        field: 'customer_id',
      );
    }

    // Validation: Job date cannot be in the future
    final endOfToday = DateTime.now().copyWith(hour: 23, minute: 59, second: 59);
    if (params.jobDate.isAfter(endOfToday)) {
      throw const ValidationException(
        message: 'Job date cannot be in the future.',
        code: 'JOB_DATE_FUTURE',
        field: 'job_date',
      );
    }

    // Validation: Amount charged must be greater than zero
    if (params.amountCharged != null && params.amountCharged! <= 0) {
      throw const ValidationException(
        message: 'Amount charged must be greater than zero.',
        code: 'AMOUNT_ZERO_OR_NEGATIVE',
        field: 'amount_charged',
      );
    }

    final now = DateTime.now();
    final job = JobEntity(
      id: const Uuid().v4(),
      userId: params.userId,
      customerId: params.customerId,
      serviceType: params.serviceType,
      jobDate: params.jobDate,
      location: params.location,
      latitude: params.latitude,
      longitude: params.longitude,
      notes: params.notes,
      amountCharged: params.amountCharged,
      followUpSent: false,
      syncStatus: SyncStatus.pending,
      isArchived: false,
      status: params.status,
      paymentStatus: params.paymentStatus,
      quotedPrice: params.quotedPrice,
      hardwareBrand: params.hardwareBrand,
      hardwareKeyway: params.hardwareKeyway,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.createJob(job);
  }
}
