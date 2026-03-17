import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/job_entity.dart';
import '../repositories/job_repository.dart';

class UpdateJobParams {
  final JobEntity job;

  UpdateJobParams({required this.job});
}

class UpdateJobUsecase implements UseCase<JobEntity, UpdateJobParams> {
  final JobRepository _repository;
  UpdateJobUsecase(this._repository);

  @override
  Future<JobEntity> call(UpdateJobParams params) async {
    final job = params.job;

    // Validation: Job date cannot be in the future
    final endOfToday = DateTime.now().copyWith(hour: 23, minute: 59, second: 59);
    if (job.jobDate.isAfter(endOfToday)) {
      throw const ValidationException(
        message: 'Job date cannot be in the future.',
        code: 'JOB_DATE_FUTURE',
        field: 'job_date',
      );
    }

    // Validation: Amount charged must be > 0 if provided
    if (job.amountCharged != null && job.amountCharged! <= 0) {
      throw const ValidationException(
        message: 'Amount charged must be greater than zero.',
        code: 'AMOUNT_ZERO_OR_NEGATIVE',
        field: 'amount_charged',
      );
    }

    final updatedJob = job.copyWith(
      updatedAt: DateTime.now(),
    );

    return _repository.updateJob(updatedJob);
  }
}
