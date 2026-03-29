import '../../domain/entities/job_audit_entry_entity.dart';

class JobAuditEntryModel {
  final String id;
  final String jobId;
  final String? userId;
  final String action;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String createdAt;

  const JobAuditEntryModel({
    required this.id,
    required this.jobId,
    this.userId,
    required this.action,
    this.oldValues,
    this.newValues,
    required this.createdAt,
  });

  factory JobAuditEntryModel.fromJson(Map<String, dynamic> json) => JobAuditEntryModel(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        userId: json['user_id'] as String?,
        action: json['action'] as String,
        oldValues: json['old_values'] as Map<String, dynamic>?,
        newValues: json['new_values'] as Map<String, dynamic>?,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'user_id': userId,
        'action': action,
        'old_values': oldValues,
        'new_values': newValues,
        'created_at': createdAt,
      };

  JobAuditEntryEntity toEntity() => JobAuditEntryEntity(
        id: id,
        jobId: jobId,
        userId: userId,
        action: action,
        oldValues: oldValues,
        newValues: newValues,
        createdAt: DateTime.parse(createdAt),
      );
}
