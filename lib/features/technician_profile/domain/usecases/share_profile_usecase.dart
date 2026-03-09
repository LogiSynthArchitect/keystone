import '../../../../core/usecases/use_case.dart';
import '../repositories/profile_repository.dart';

class ShareProfileUsecase implements NoParamsUseCase<String> {
  final ProfileRepository _repository;
  ShareProfileUsecase(this._repository);

  @override
  Future<String> call() async {
    final profile = await _repository.getProfile();
    if (profile == null) return '';
    return profile.profileUrl;
  }
}
