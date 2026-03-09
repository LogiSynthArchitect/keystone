import '../../../../core/usecases/use_case.dart';
import '../entities/job_entity.dart';
import '../repositories/job_repository.dart';

class GetJobUsecase implements UseCase<JobEntity, String> {
  final JobRepository _repository;
  GetJobUsecase(this._repository);

  @override
  Future<JobEntity> call(String id) => _repository.getJobById(id);
}
