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

  Future<JobEntity> call(UpdatePaymentStatusParams params) =>
      _repository.updatePaymentStatus(
        params.jobId,
        params.paymentStatus,
        params.paymentMethod,
        params.editedBy,
      );
}
