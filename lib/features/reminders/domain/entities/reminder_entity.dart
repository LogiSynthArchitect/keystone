class ReminderEntity {
  final String id;
  final String userId;
  final String jobId;
  final String type;           // 'unpaid_job' | 'stuck_in_progress' | 'followup_pending' | 'followup_no_response'
  final String status;         // 'active' | 'dismissed' | 'snoozed' | 'resolved'
  final DateTime createdAt;
  final DateTime? snoozedUntil;
  final DateTime? dismissedAt;

  const ReminderEntity({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.snoozedUntil,
    this.dismissedAt,
  });

  ReminderEntity copyWith({
    String? id,
    String? userId,
    String? jobId,
    String? type,
    String? status,
    DateTime? createdAt,
    DateTime? snoozedUntil,
    DateTime? dismissedAt,
  }) => ReminderEntity(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    jobId: jobId ?? this.jobId,
    type: type ?? this.type,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    dismissedAt: dismissedAt ?? this.dismissedAt,
  );
}
