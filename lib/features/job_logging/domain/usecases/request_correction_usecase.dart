import '../../../../core/usecases/use_case.dart';
import '../entities/correction_request_entity.dart';
import '../repositories/correction_request_repository.dart';

class RequestCorrectionParams {
  final String jobId;
  final String userId;
  final String reason;

  const RequestCorrectionParams({
    required this.jobId,
    required this.userId,
    required this.reason,
  });
}

class RequestCorrectionUsecase implements UseCase<CorrectionRequestEntity, RequestCorrectionParams> {
  final CorrectionRequestRepository _repository;

  RequestCorrectionUsecase(this._repository);

  @override
  Future<CorrectionRequestEntity> call(RequestCorrectionParams params) async {
    final request = CorrectionRequestEntity(
      id: '',
      jobId: params.jobId,
      userId: params.userId,
      reason: params.reason,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return _repository.createRequest(request);
  }
}
