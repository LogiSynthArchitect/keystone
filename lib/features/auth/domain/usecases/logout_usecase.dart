import '../../../../core/usecases/use_case.dart';
import '../repositories/auth_repository.dart';

class LogoutUsecase implements NoParamsUseCase<void> {
  final AuthRepository _repository;
  LogoutUsecase(this._repository);

  @override
  Future<void> call() => _repository.signOut();
}
