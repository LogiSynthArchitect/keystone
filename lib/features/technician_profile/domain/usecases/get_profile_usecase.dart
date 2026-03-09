import '../../../../core/usecases/use_case.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileUsecase implements NoParamsUseCase<ProfileEntity?> {
  final ProfileRepository _repository;
  GetProfileUsecase(this._repository);

  @override
  Future<ProfileEntity?> call() => _repository.getProfile();
}
