import '../../../../core/usecases/use_case.dart';
import '../repositories/customer_repository.dart';

class MergeCustomersParams {
  final String targetId;
  final String sourceId;
  const MergeCustomersParams({required this.targetId, required this.sourceId});
}

class MergeCustomersUsecase implements UseCase<void, MergeCustomersParams> {
  final CustomerRepository _repository;
  MergeCustomersUsecase(this._repository);

  @override
  Future<void> call(MergeCustomersParams params) async {
    if (params.targetId == params.sourceId) return;
    await _repository.mergeCustomers(params.targetId, params.sourceId);
  }
}
