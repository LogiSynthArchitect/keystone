import '../../../../core/usecases/use_case.dart';
import '../repositories/customer_repository.dart';

class SyncOfflineCustomersUsecase implements UseCase<void, void> {
  final CustomerRepository _repository;
  SyncOfflineCustomersUsecase(this._repository);

  @override
  Future<void> call([void params]) async {
    return _repository.syncPendingCustomers();
  }
}
