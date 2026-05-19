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

  CorrectionRequestEntity copyWith({
    String? id,
    String? jobId,
    String? userId,
    String? reason,
    CorrectionRequestStatus? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CorrectionRequestEntity(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
