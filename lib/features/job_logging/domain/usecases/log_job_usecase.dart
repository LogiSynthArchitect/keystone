import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/job_entity.dart';
import '../repositories/job_repository.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';

class LogJobParams {
  final String userId;
  final String customerId;
  final ServiceType serviceType;
  final DateTime jobDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final double? amountCharged;

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
  });
}

class LogJobUsecase implements UseCase<JobEntity, LogJobParams> {
  final JobRepository _repository;
  LogJobUsecase(this._repository);

  @override
  Future<JobEntity> call(LogJobParams params) async {
    if (params.jobDate.isAfter(DateTime.now())) {
      throw const ValidationException(
        message: 'Job date cannot be in the future.',
        code: 'JOB_DATE_FUTURE',
        field: 'job_date',
      );
    }
    if (params.amountCharged != null && params.amountCharged! < 0) {
      throw const ValidationException(
        message: 'Amount charged cannot be negative.',
        code: 'AMOUNT_NEGATIVE',
        field: 'amount_charged',
      );
    }

    final now = DateTime.now();
    final job = JobEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      createdAt: now,
      updatedAt: now,
    );

    return _repository.createJob(job);
  }
}
