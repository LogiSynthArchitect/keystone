import '../../../../core/usecases/use_case.dart';
import '../repositories/job_repository.dart';

class SyncOfflineJobsUsecase implements NoParamsUseCase<void> {
  final JobRepository _repository;
  SyncOfflineJobsUsecase(this._repository);

  @override
  Future<void> call() => _repository.syncPendingJobs();
}
