enum CorrectionRequestStatus { pending, approved, rejected }

class CorrectionRequestEntity {
  final String id;
  final String jobId;
  final String userId;
  final String reason;
  final CorrectionRequestStatus status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CorrectionRequestEntity({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.reason,
    this.status = CorrectionRequestStatus.pending,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });
}
