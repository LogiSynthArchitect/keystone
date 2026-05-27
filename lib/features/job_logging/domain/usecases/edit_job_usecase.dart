import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/job_entity.dart';
import '../repositories/job_repository.dart';

class EditJobParams {
  final String jobId;
  final Map<String, dynamic> changes;
  final String editedBy;

  const EditJobParams({
    required this.jobId,
    required this.changes,
    required this.editedBy,
  });
}

class EditJobUsecase implements UseCase<JobEntity, EditJobParams> {
  final JobRepository _repository;
  EditJobUsecase(this._repository);

  @override
  Future<JobEntity> call(EditJobParams params) async {
    // Fetch current job to validate cross-field integrity
    final job = await _repository.getJobById(params.jobId);
    if (job == null) {
      throw const ValidationException(
        message: 'Job not found.',
        code: 'JOB_NOT_FOUND',
        field: 'job_id',
      );
    }

    // Merge changes to determine final status and paymentStatus
    final finalStatus = (params.changes['status'] as String?) ?? job.status;
    final finalPayment =
        (params.changes['paymentStatus'] as String?) ?? job.paymentStatus;

    final paymentErr =
        JobEntity.validatePaymentForStatus(finalStatus, finalPayment);
    if (paymentErr != null) {
      throw ValidationException(
        message: paymentErr,
        code: 'INVALID_PAYMENT_FOR_STATUS',
        field: 'payment_status',
      );
    }

    return _repository.editJob(params.jobId, params.changes, params.editedBy);
  }
}
