import '../../../../core/errors/validation_exception.dart';
import '../entities/job_entity.dart';
import '../repositories/job_repository.dart';

class UpdatePaymentStatusParams {
  final String jobId;
  final String paymentStatus;
  final String? paymentMethod;
  final String editedBy;

  const UpdatePaymentStatusParams({
    required this.jobId,
    required this.paymentStatus,
    this.paymentMethod,
    required this.editedBy,
  });
}

class UpdatePaymentStatusUsecase {
  final JobRepository _repository;
  UpdatePaymentStatusUsecase(this._repository);

  Future<JobEntity> call(UpdatePaymentStatusParams params) async {
    final job = await _repository.getJobById(params.jobId);
    if (job == null) {
      throw const ValidationException(
        message: 'Job not found.',
        code: 'JOB_NOT_FOUND',
        field: 'job_id',
      );
    }

    final paymentErr = JobEntity.validatePaymentForStatus(
      job.status,
      params.paymentStatus,
    );
    if (paymentErr != null) {
      throw ValidationException(
        message: paymentErr,
        code: 'INVALID_PAYMENT_FOR_STATUS',
        field: 'payment_status',
      );
    }

    return _repository.updatePaymentStatus(
      params.jobId,
      params.paymentStatus,
      params.paymentMethod,
      params.editedBy,
    );
  }
}
