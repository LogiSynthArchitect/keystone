import '../../domain/entities/correction_request_entity.dart';

class CorrectionRequestModel {
  final String id;
  final String jobId;
  final String userId;
  final String reason;
  final String status;
  final String? adminNotes;
  final String createdAt;
  final String updatedAt;

  const CorrectionRequestModel({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.reason,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CorrectionRequestModel.fromJson(Map<String, dynamic> json) =>
      CorrectionRequestModel(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        userId: json['user_id'] as String,
        reason: json['reason'] as String,
        status: json['status'] as String,
        adminNotes: json['admin_notes'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'user_id': userId,
        'reason': reason,
        'status': status,
        'admin_notes': adminNotes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  CorrectionRequestEntity toEntity() => CorrectionRequestEntity(
        id: id,
        jobId: jobId,
        userId: userId,
        reason: reason,
        status: _parseStatus(status),
        adminNotes: adminNotes,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  static CorrectionRequestStatus _parseStatus(String status) {
    switch (status) {
      case 'approved': return CorrectionRequestStatus.approved;
      case 'rejected': return CorrectionRequestStatus.rejected;
      default:         return CorrectionRequestStatus.pending;
    }
  }
}
