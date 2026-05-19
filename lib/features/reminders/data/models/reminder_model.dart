import '../../domain/entities/reminder_entity.dart';

class ReminderModel extends ReminderEntity {
  const ReminderModel({
    required super.id,
    required super.userId,
    required super.jobId,
    required super.type,
    required super.status,
    required super.createdAt,
    super.snoozedUntil,
    super.dismissedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    jobId: json['job_id'] as String,
    type: json['type'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    snoozedUntil: json['snoozed_until'] != null ? DateTime.parse(json['snoozed_until'] as String) : null,
    dismissedAt: json['dismissed_at'] != null ? DateTime.parse(json['dismissed_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'job_id': jobId,
    'type': type,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'snoozed_until': snoozedUntil?.toIso8601String(),
    'dismissed_at': dismissedAt?.toIso8601String(),
  };
}
