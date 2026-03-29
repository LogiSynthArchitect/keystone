class JobAuditEntryEntity {
  final String id;
  final String jobId;
  final String? userId; // Admin who performed the action
  final String action; // 'created', 'updated', 'status_changed', 'archived', 'correction_requested', 'correction_approved', 'correction_rejected'
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
}
