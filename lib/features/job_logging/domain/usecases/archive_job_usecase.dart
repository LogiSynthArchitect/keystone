import '../../../../core/usecases/use_case.dart';
import '../repositories/job_repository.dart';

class ArchiveJobUsecase implements UseCase<void, String> {
  final JobRepository _repository;
  ArchiveJobUsecase(this._repository);

  @override
  Future<void> call(String id) async {
    return _repository.archiveJob(id);
  }
}
