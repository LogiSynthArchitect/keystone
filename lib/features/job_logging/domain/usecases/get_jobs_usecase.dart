import '../../../../core/usecases/use_case.dart';
import '../entities/job_entity.dart';
import '../repositories/job_repository.dart';

class GetJobsParams {
  final int limit;
  final int offset;
  const GetJobsParams({this.limit = 25, this.offset = 0});
}

class GetJobsUsecase implements UseCase<List<JobEntity>, GetJobsParams> {
  final JobRepository _repository;
  GetJobsUsecase(this._repository);

  @override
  Future<List<JobEntity>> call(GetJobsParams params) =>
      _repository.getJobs(limit: params.limit, offset: params.offset);
}
