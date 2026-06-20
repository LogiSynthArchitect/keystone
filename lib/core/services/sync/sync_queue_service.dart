import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'mutation_task.dart';

/// Centralized outbox queue for offline-first mutations.
///
/// Every create/update/delete flows through this queue instead of making
/// inline Supabase calls. The SyncWorker drains the queue when connectivity
/// is restored.
///
/// Key features:
/// - **Mutation squashing**: consecutive UPDATEs to the same recordId merge
///   payloads so the worker fires one call, not N.
/// - **Dead letter queue**: tasks that fail [maxRetries] times are quarantined.
/// - **Concurrency guard**: dequeue() atomically marks tasks as 'processing'.
class SyncQueueService {
  static const String _boxName = 'sync_queue';
  static const int maxRetries = 5;

  Box get _queue => Hive.box(_boxName);

  /// Enqueue a mutation. Returns the [taskId] so callers can markComplete.
  ///
  /// **Lifecycle squashing:**
  /// - `CREATE` + `DELETE` → annihilate both (the record never existed).
  /// - `DELETE` + `CREATE` → DELETE is stale, replace with CREATE.
  /// - `UPDATE` over pending `DELETE` → no-op (DELETE wins).
  ///
  /// **UPDATE squashing:**
  /// Consecutive UPDATEs to the same [recordId] + [tableName] merge payloads
  /// so the SyncWorker fires one call, not N.
  Future<String> enqueue({
    required String tableName,
    required String operation,
    required Map<String, dynamic> payload,
    required String recordId,
  }) async {
    // ── Lifecycle annihilation ──────────────────────────────────────────
    if (operation == 'DELETE') {
      // CREATE + DELETE = annihilate
      final createKey = _findPendingOp(tableName, recordId, 'INSERT');
      if (createKey != null) {
        await _queue.delete(createKey);
        debugPrint('[KS:SYNC:QUEUE] Annihilated CREATE+DELETE for $tableName/$recordId');
        return ''; // no task needed — record never existed
      }
    }

    if (operation == 'INSERT') {
      // DELETE + CREATE = DELETE is stale, remove it
      final deleteKey = _findPendingOp(tableName, recordId, 'DELETE');
      if (deleteKey != null) {
        await _queue.delete(deleteKey);
        debugPrint('[KS:SYNC:QUEUE] Stale DELETE removed for $tableName/$recordId (CREATE supersedes)');
      }
    }

    if (operation == 'UPDATE') {
      // UPDATE over pending DELETE = no-op (DELETE wins)
      final deleteKey = _findPendingOp(tableName, recordId, 'DELETE');
      if (deleteKey != null) {
        debugPrint('[KS:SYNC:QUEUE] Ignored UPDATE for $tableName/$recordId — DELETE pending');
        return _findLatestKey(tableName, recordId) ?? '';
      }

      // Squash: merge payloads for consecutive UPDATEs
      final existingKey = _findPendingUpdate(tableName, recordId);
      if (existingKey != null) {
        final raw = _queue.get(existingKey) as Map?;
        if (raw != null) {
          final existing = MutationTask.fromJson(Map<String, dynamic>.from(raw));
          final mergedPayload = {...existing.payload, ...payload};
          final squashed = existing.copyWith(payload: mergedPayload);
          await _queue.put(existingKey, squashed.toJson());
          debugPrint('[KS:SYNC:QUEUE] Squashed UPDATE for $tableName/$recordId');
          return existingKey;
        }
      }
    }

    final task = MutationTask(
      taskId: const Uuid().v4(),
      tableName: tableName,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now(),
      recordId: recordId,
    );
    await _queue.put(task.taskId, task.toJson());
    debugPrint('[KS:SYNC:QUEUE] Enqueued $operation $tableName/$recordId');
    return task.taskId;
  }

  /// Dequeue the oldest pending task. Marks it 'processing' atomically.
  Future<MutationTask?> dequeue() async {
    final pending = <MapEntry<String, MutationTask>>[];
    for (final key in _queue.keys) {
      final raw = _queue.get(key) as Map?;
      if (raw == null) continue;
      final task = MutationTask.fromJson(Map<String, dynamic>.from(raw));
      if (task.status == 'pending') {
        pending.add(MapEntry(key.toString(), task));
      }
    }
    if (pending.isEmpty) return null;

    pending.sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));
    final oldest = pending.first;
    final updated = oldest.value.copyWith(status: 'processing');
    await _queue.put(oldest.key, updated.toJson());
    return updated;
  }

  /// Remove a completed task from the queue.
  Future<void> markComplete(String taskId) async {
    await _queue.delete(taskId);
  }

  /// Mark a task as failed. Past [maxRetries], becomes a dead letter.
  Future<void> markFailed(String taskId, String error) async {
    final raw = _queue.get(taskId) as Map?;
    if (raw == null) return;
    final task = MutationTask.fromJson(Map<String, dynamic>.from(raw));
    final newRetryCount = task.retryCount + 1;
    final isDeadLetter = newRetryCount >= maxRetries;
    final updated = task.copyWith(
      retryCount: newRetryCount,
      status: isDeadLetter ? 'failed' : 'pending',
      lastError: error,
    );
    await _queue.put(taskId, updated.toJson());

    if (isDeadLetter) {
      debugPrint('[KS:SYNC:QUEUE] Task $taskId → dead letter after $newRetryCount failures');
    }
  }

  /// Return all dead letter entries (newest first).
  Future<List<MutationTask>> getDeadLetters() async {
    final result = <MutationTask>[];
    for (final key in _queue.keys) {
      final raw = _queue.get(key) as Map?;
      if (raw == null) continue;
      final task = MutationTask.fromJson(Map<String, dynamic>.from(raw));
      if (task.status == 'failed') result.add(task);
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Count pending + processing tasks.
  int pendingCount() {
    int count = 0;
    for (final key in _queue.keys) {
      final raw = _queue.get(key) as Map?;
      if (raw == null) continue;
      final task = MutationTask.fromJson(Map<String, dynamic>.from(raw));
      if (task.status == 'pending' || task.status == 'processing') count++;
    }
    return count;
  }

  /// Check if a task still exists in the queue (pending/processing/failed).
  /// Used by the SyncWorker for dependency tracking — if the parent task
  /// is gone (marked complete), the dependent is unblocked.
  bool exists(String taskId) {
    return _queue.containsKey(taskId);
  }

  /// Clear all tasks (after full re-sync).
  Future<void> clear() async {
    await _queue.clear();
  }

  // ---------------------------------------------------------------------------
  String? _findPendingOp(String tableName, String recordId, String operation) {
    for (final key in _queue.keys) {
      final raw = _queue.get(key) as Map?;
      if (raw == null) continue;
      final task = MutationTask.fromJson(Map<String, dynamic>.from(raw));
      if (task.tableName == tableName &&
          task.recordId == recordId &&
          task.operation == operation &&
          (task.status == 'pending' || task.status == 'processing')) {
        return key.toString();
      }
    }
    return null;
  }

  /// Return the key of the most recent task for a record (any operation).
  String? _findLatestKey(String tableName, String recordId) {
    String? latestKey;
    DateTime? latestTime;
    for (final key in _queue.keys) {
      final raw = _queue.get(key) as Map?;
      if (raw == null) continue;
      final task = MutationTask.fromJson(Map<String, dynamic>.from(raw));
      if (task.tableName == tableName && task.recordId == recordId) {
        if (latestTime == null || task.createdAt.isAfter(latestTime)) {
          latestTime = task.createdAt;
          latestKey = key.toString();
        }
      }
    }
    return latestKey;
  }

  String? _findPendingUpdate(String tableName, String recordId) {
    for (final key in _queue.keys) {
      final raw = _queue.get(key) as Map?;
      if (raw == null) continue;
      final task = MutationTask.fromJson(Map<String, dynamic>.from(raw));
      if (task.tableName == tableName &&
          task.recordId == recordId &&
          task.operation == 'UPDATE' &&
          (task.status == 'pending' || task.status == 'processing')) {
        return key.toString();
      }
    }
    return null;
  }
}
