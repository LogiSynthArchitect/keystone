import '../../../../core/usecases/use_case.dart';
import '../../../../core/storage/hive_service.dart';
import '../repositories/auth_repository.dart';

class LogoutUsecase implements NoParamsUseCase<void> {
  final AuthRepository _repository;
  LogoutUsecase(this._repository);

  @override
  Future<void> call() async {
    await _repository.signOut();
    // Task 2 fix: Guarantee zero data bleed between sessions
    await HiveService.clearAll();
  }
}
