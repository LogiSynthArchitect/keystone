import '../entities/correction_request_entity.dart';

abstract class CorrectionRequestRepository {
  Future<CorrectionRequestEntity> createRequest(CorrectionRequestEntity request);
  Future<List<CorrectionRequestEntity>> getMyRequests();
  Future<List<CorrectionRequestEntity>> getAllPendingRequests();
  Future<void> approveRequest(String requestId, String jobId, Map<String, dynamic> updates);
  Future<void> rejectRequest(String requestId, {String? adminNotes});
}
