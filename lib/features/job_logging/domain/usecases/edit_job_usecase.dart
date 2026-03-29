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
    return _repository.editJob(params.jobId, params.changes, params.editedBy);
  }
}
