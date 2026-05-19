class JobAuditEntryEntity {
  final String id;
  final String jobId;
  final String? userId;
  final String action;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime createdAt;

  const JobAuditEntryEntity({
    required this.id,
    required this.jobId,
    this.userId,
    required this.action,
    this.oldValues,
    this.newValues,
    required this.createdAt,
  });

  JobAuditEntryEntity copyWith({
    String? id,
    String? jobId,
    String? userId,
    String? action,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    DateTime? createdAt,
  }) {
    return JobAuditEntryEntity(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
