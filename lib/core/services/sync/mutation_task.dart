import 'dart:convert';

/// A single mutation waiting to be synced to Supabase.
///
/// Stored as JSON in the `sync_queue` Hive box under the task's [taskId] key.
/// The [recordId] is promoted to a top-level field so the queue can perform
/// mutation squashing: before enqueuing an UPDATE for a record, check if a
/// pending UPDATE already exists for the same [recordId] and merge payloads.
class MutationTask {
  final String taskId;
  final String tableName;
  final String operation; // INSERT | UPDATE | DELETE
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String recordId;
  final String status; // pending | processing | failed
  final String? lastError;

  /// Optional parent taskId that must complete before this task is processed.
  /// Example: a Job task depends on its Customer task — the worker skips
  /// the Job until the Customer's task is dequeued (i.e., no longer exists
  /// in the queue).
  final String? dependsOn;

  const MutationTask({
    required this.taskId,
    required this.tableName,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    required this.recordId,
    this.status = 'pending',
    this.lastError,
    this.dependsOn,
  });

  MutationTask copyWith({
    String? taskId,
    String? tableName,
    String? operation,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    String? recordId,
    String? status,
    String? lastError,
    Object? dependsOn = _sentinel,
    bool clearError = false,
  }) {
    return MutationTask(
      taskId: taskId ?? this.taskId,
      tableName: tableName ?? this.tableName,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      recordId: recordId ?? this.recordId,
      status: status ?? this.status,
      lastError: clearError ? null : (lastError ?? this.lastError),
      dependsOn: dependsOn == _sentinel ? this.dependsOn : dependsOn as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'tableName': tableName,
        'operation': operation,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'recordId': recordId,
        'status': status,
        'lastError': lastError,
        if (dependsOn != null) 'dependsOn': dependsOn,
      };

  factory MutationTask.fromJson(Map<String, dynamic> json) => MutationTask(
        taskId: json['taskId'] as String,
        tableName: json['tableName'] as String,
        operation: json['operation'] as String,
        payload: (json['payload'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v),
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
        recordId: json['recordId'] as String,
        status: json['status'] as String? ?? 'pending',
        lastError: json['lastError'] as String?,
        dependsOn: json['dependsOn'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory MutationTask.fromJsonString(String source) =>
      MutationTask.fromJson(jsonDecode(source) as Map<String, dynamic>);

  static const _sentinel = Object();
}
