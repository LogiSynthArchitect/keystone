import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../features/customer_history/data/datasources/customer_remote_datasource.dart';
import '../../../features/job_logging/data/datasources/job_remote_datasource.dart';
import '../../network/connectivity_service.dart';
import '../../storage/hive_service.dart';
import 'mutation_task.dart';
import 'sync_queue_service.dart';

/// Drains the centralized mutation outbox queue (SyncQueueService) and
/// replays each batch against Supabase via the existing batch_sync_* RPCs.
///
/// Design:
/// - Tasks are dequeued FIFO, grouped by [tableName].
/// - Each group is chunked into batches of [batchSize] (50) to avoid
///   large request payloads.
/// - Heavy JSON serialization is offloaded to [Isolate.run] so the UI
///   thread is never blocked during sync bursts.
/// - After each chunk, the worker yields via `await Future.delayed(Duration.zero)`
///   to allow the event loop to process pending frames / isolates.
/// - Dependencies: tasks with a non-null [dependsOn] are skipped until
///   the parent taskId is removed from the queue.
///
/// Threading model:
///   Main isolate only. JSON serialization is the only heavy operation;
///   it ships to an ephemeral isolate via Isolate.run. No long-lived
///   background isolate — the caller (SyncOrchestrator, ConnectivityService)
///   decides when to invoke processQueue().
class SyncWorker {
  static const int batchSize = 50;

  final SyncQueueService _queue;
  final ConnectivityService _connectivity;
  final CustomerRemoteDatasource _customerRemote;
  final JobRemoteDatasource _jobRemote;

  SyncWorker({
    required SyncQueueService queue,
    required ConnectivityService connectivity,
    required CustomerRemoteDatasource customerRemote,
    required JobRemoteDatasource jobRemote,
  })  : _queue = queue,
        _connectivity = connectivity,
        _customerRemote = customerRemote,
        _jobRemote = jobRemote;

  /// Process all pending tasks in the queue.
  ///
  /// Returns the number of successfully processed tasks.
  /// Fails fast on connectivity loss — remaining tasks stay in queue.
  Future<int> processQueue() async {
    if (!await _connectivity.isConnected) return 0;
    if (_queue.pendingCount() == 0) return 0;

    int processed = 0;

    // Collect all pending tasks before draining (snapshot)
    final tasks = await _collectPending();
    if (tasks.isEmpty) return 0;

    // Group by tableName for batch sync
    final grouped = <String, List<MutationTask>>{};
    for (final task in tasks) {
      grouped.putIfAbsent(task.tableName, () => []).add(task);
    }

    // Process each table group in priority order
    const tableOrder = ['customers', 'jobs'];
    for (final tableName in tableOrder) {
      final group = grouped.remove(tableName);
      if (group == null || group.isEmpty) continue;
      processed += await _processTableGroup(tableName, group);
    }

    // Remaining tables (fallback for any future tables)
    for (final entry in grouped.entries) {
      processed += await _processTableGroup(entry.key, entry.value);
    }

    return processed;
  }

  /// Process all tasks for a single table, chunked by [batchSize].
  Future<int> _processTableGroup(String tableName, List<MutationTask> tasks) async {
    int processed = 0;

    for (var i = 0; i < tasks.length; i += batchSize) {
      // Yield to event loop between chunks
      if (i > 0) {
        await Future.delayed(Duration.zero);
      }

      final chunk = tasks.sublist(i, (i + batchSize).clamp(0, tasks.length));

      // Filter out dependency-blocked tasks
      final ready = chunk.where((t) => !_isDependencyBlocked(t)).toList();
      if (ready.isEmpty) continue;

      // Separate operations — deletions handled one-by-one, upserts in batch
      final deletes = ready.where((t) => t.operation == 'DELETE').toList();
      final upserts = ready.where((t) => t.operation != 'DELETE').toList();

      // Process deletions first (referential integrity)
      for (final task in deletes) {
        try {
          await _executeDelete(tableName, task.recordId);
          await _queue.markComplete(task.taskId);
          processed++;
        } catch (e) {
          await _queue.markFailed(task.taskId, e.toString());
        }
      }

      // Process upserts in batch
      if (upserts.isNotEmpty) {
        final actualProcessed = await _executeBatchUpsert(tableName, upserts);
        processed += actualProcessed;
      }
    }

    return processed;
  }

  Future<void> _executeDelete(String tableName, String recordId) async {
    switch (tableName) {
      case 'customers':
        await _customerRemote.deleteCustomer(recordId);
        break;
      case 'jobs':
        // Jobs are soft-deleted (tombstone) — the `is_deleted` flag is set
        // locally and the tombstone record is upserted via batch sync RPC
        // so the server can mark it deleted. No hard-delete RPC needed.
        debugPrint('[KS:SYNC:WORKER] DELETE for jobs table — tombstone handled via batch upsert');
        break;
      default:
        debugPrint('[KS:SYNC:WORKER] No delete handler for table: $tableName');
    }
  }

  Future<int> _executeBatchUpsert(String tableName, List<MutationTask> tasks) async {
    switch (tableName) {
      case 'customers':
        return await _batchSyncCustomers(tasks);
      case 'jobs':
        return await _batchSyncJobs(tasks);
      default:
        debugPrint('[KS:SYNC:WORKER] No batch handler for table: $tableName');
        return 0;
    }
  }

  /// Extract userId from the first customer task's payload.
  /// Every customer mutation includes it.
  String _extractUserId(List<MutationTask> tasks) {
    for (final task in tasks) {
      final uid = task.payload['user_id'] as String?;
      if (uid != null && uid.isNotEmpty) return uid;
    }
    return '';
  }

  /// Serialize a list of model payloads to JSON in an isolate, then
  /// send to the Supabase batch sync RPC.
  Future<int> _batchSyncCustomers(List<MutationTask> tasks) async {
    final payloads = tasks.map((t) => t.payload).toList();
    final userId = _extractUserId(tasks);
    if (userId.isEmpty) {
      debugPrint('[KS:SYNC:WORKER] Cannot batch sync customers: no user_id in payload');
      return 0;
    }

    // Heavy serialization → ephemeral isolate
    final jsonList = await Isolate.run(() {
      return payloads.map((p) => jsonEncode(p)).toList();
    });

    final decoded = jsonList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    final result = await _customerRemote.batchSyncCustomers(userId, decoded);

    final syncedList = result['synced'] as List<dynamic>? ?? [];
    final failedList = result['failed'] as List<dynamic>? ?? [];

    // Mark synced tasks complete
    for (final syncedItem in syncedList) {
      final localId = syncedItem['local_id'] as String?;
      if (localId == null) continue;
      final matchingTask = tasks.where((t) => t.recordId == localId).firstOrNull;
      if (matchingTask != null) {
        await _queue.markComplete(matchingTask.taskId);
      }
    }

    // Mark failed tasks
    for (final failedItem in failedList) {
      final localId = failedItem['local_id'] as String?;
      if (localId == null) continue;
      final matchingTask = tasks.where((t) => t.recordId == localId).firstOrNull;
      if (matchingTask != null) {
        final error = failedItem['error'] as String? ?? 'Server rejection';
        await _queue.markFailed(matchingTask.taskId, error);
      }
    }

    return syncedList.length;
  }

  Future<int> _batchSyncJobs(List<MutationTask> tasks) async {
    final payloads = tasks.map((t) => t.payload).toList();
    final userId = _extractUserId(tasks);
    if (userId.isEmpty) {
      debugPrint('[KS:SYNC:WORKER] Cannot batch sync jobs: no user_id in payload');
      return 0;
    }

    final jsonList = await Isolate.run(() {
      return payloads.map((p) => jsonEncode(p)).toList();
    });

    final decoded = jsonList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    final result = await _jobRemote.batchSync(userId, decoded);

    final syncedList = result['synced'] as List<dynamic>? ?? [];
    final failedList = result['failed'] as List<dynamic>? ?? [];

    for (final syncedItem in syncedList) {
      final localId = syncedItem['local_id'] as String?;
      if (localId == null) continue;
      final matchingTask = tasks.where((t) => t.recordId == localId).firstOrNull;
      if (matchingTask != null) {
        await _queue.markComplete(matchingTask.taskId);
      }
    }

    for (final failedItem in failedList) {
      final localId = failedItem['local_id'] as String?;
      if (localId == null) continue;
      final matchingTask = tasks.where((t) => t.recordId == localId).firstOrNull;
      if (matchingTask != null) {
        final error = failedItem['error'] as String? ?? 'Server rejection';
        await _queue.markFailed(matchingTask.taskId, error);
      }
    }

    return syncedList.length;
  }

  /// Check if a task is blocked by an unresolved dependency.
  bool _isDependencyBlocked(MutationTask task) {
    if (task.dependsOn == null) return false;
    // Task still in queue? Then parent hasn't been processed yet.
    return _queue.exists(task.dependsOn!);
  }

  /// Snapshot all pending tasks from the queue.
  /// Must not hold Hive box open across async gaps (single enumeration).
  Future<List<MutationTask>> _collectPending() async {
    final result = <MutationTask>[];
    // Read all tasks at once into memory (snapshot)
    final box = Hive.box(HiveService.syncQueueBox);
    for (final key in box.keys) {
      final raw = box.get(key) as Map?;
      if (raw == null) continue;
      final task = MutationTask.fromJson(Map<String, dynamic>.from(raw));
      if (task.status == 'pending') {
        result.add(task);
      }
    }
    // Sort by creation order (oldest first)
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }
}
