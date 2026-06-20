import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/storage/hive_service.dart';
import '../../data/datasources/recurring_schedule_local_datasource.dart';
import '../../data/datasources/recurring_schedule_remote_datasource.dart';
import '../../data/models/recurring_schedule_model.dart';
import '../../domain/entities/recurring_schedule_entity.dart';
import '../../../job_logging/data/models/job_model.dart';
import '../../../../core/constants/app_enums.dart';

final recurringScheduleLocalDatasourceProvider = Provider<RecurringScheduleLocalDatasource>((ref) => RecurringScheduleLocalDatasource());
final recurringScheduleRemoteDatasourceProvider = Provider<RecurringScheduleRemoteDatasource>((ref) => RecurringScheduleRemoteDatasource(ref.watch(supabaseClientProvider)));

class RecurringScheduleNotifier extends StateNotifier<AsyncValue<List<RecurringScheduleEntity>>> {
  final Ref _ref;
  RecurringScheduleNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> load() async {
    // Sync pending to remote first
    await syncPending();
    // Then pull remote items (PULL phase)
    await _pullFromRemote();
    try {
      final items = await _ref.read(recurringScheduleLocalDatasourceProvider).getAll();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _pullFromRemote() async {
    final connectivity = _ref.read(connectivityServiceProvider);
    if (!await connectivity.isConnected) return;
    final userId = _ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;
    try {
      final remote = _ref.read(recurringScheduleRemoteDatasourceProvider);
      final local = _ref.read(recurringScheduleLocalDatasourceProvider);
      final remoteModels = await remote.getAll(userId);
      for (final model in remoteModels) {
        await local.save(model.toEntity());
      }
    } catch (e) {
      debugPrint('[KS:RECURRING] Remote pull failed: $e');
    }
  }

  Future<void> add({
    required String customerId,
    required String customerName,
    required String serviceType,
    String? serviceTypeId,
    required String intervalType,
    required DateTime nextDueDate,
    String? notes,
  }) async {
    final userId = _ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;
    final entity = RecurringScheduleEntity(
      id: const Uuid().v4(),
      userId: userId,
      customerId: customerId,
      customerName: customerName,
      serviceType: serviceType,
      serviceTypeId: serviceTypeId,
      intervalType: intervalType,
      nextDueDate: nextDueDate,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _ref.read(recurringScheduleLocalDatasourceProvider).save(entity);
    await load();
  }

  Future<void> delete(String id) async {
    await _ref.read(recurringScheduleLocalDatasourceProvider).delete(id);
    await load();
  }

  /// Sync pending schedules to Supabase.
  Future<void> syncPending() async {
    final connectivity = _ref.read(connectivityServiceProvider);
    if (!await connectivity.isConnected) return;
    final pending = await _ref.read(recurringScheduleLocalDatasourceProvider).getPending();
    if (pending.isEmpty) return;
    final remote = _ref.read(recurringScheduleRemoteDatasourceProvider);
    final local = _ref.read(recurringScheduleLocalDatasourceProvider);
    for (final entity in pending) {
      try {
        final model = RecurringScheduleModel.fromEntity(entity);
        final remoteModel = await remote.upsert(model.toJson());
        await local.markSynced(remoteModel.toEntity());
      } catch (e) {
        debugPrint('[KS:RECURRING] Sync failed for ${entity.id}: $e');
      }
    }
  }

  /// Advance [schedule.nextDueDate] by its interval.
  /// Advance [schedule.nextDueDate] to the next occurrence.
  /// All dates use local-midnight semantics (no time component, no UTC offset).
  /// The device's local timezone is the authority — Ghana is GMT+0 year-round.
  DateTime _advanceNextDueDate(RecurringScheduleEntity schedule) {
    final next = schedule.nextDueDate;
    switch (schedule.intervalType) {
      case 'weekly':   return next.add(const Duration(days: 7));
      case 'monthly':  return _addMonths(next, 1);
      case 'quarterly': return _addMonths(next, 3);
      case 'yearly':   return _addMonths(next, 12);
      default:         return next.add(const Duration(days: 30));
    }
  }

  /// Add [months] to [date], clamping day to the last valid day of the target month.
  /// Prevents crashes when advancing from e.g. Jan 31 → Feb 28 (not Feb 31).
  static DateTime _addMonths(DateTime date, int months) {
    final targetMonth = (date.month - 1 + months) % 12 + 1;
    final targetYear = date.year + ((date.month - 1 + months) ~/ 12);
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(targetYear, targetMonth, day);
  }

  /// Generate jobs for all due schedules, advance their nextDueDate.
  /// Uses Write-Ahead Log for crash atomicity — payload-first, trigger-second.
  /// Returns the number of jobs created.
  Future<int> generateDueJobs() async {
    final items = state.valueOrNull ?? [];
    final due = items.where((s) => s.isActive && s.isDue).toList();
    if (due.isEmpty) return 0;

    final userId = _ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return 0;

    final batchId = const Uuid().v4();
    final meta = HiveService.meta;
    int count = 0;

    // Phase 0: Write WAL entry (proves generation STARTED)
    await meta.put('pending_schedule_gen:$batchId', {
      'batch_id': batchId,
      'target_schedule_ids': due.map((s) => s.id).toList(),
      'state': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
    await meta.flush();
    debugPrint('[KS:RECURRING] WAL written for batch $batchId (${due.length} schedules)');

    try {
      final jobsBox = HiveService.jobs;
      final localDs = _ref.read(recurringScheduleLocalDatasourceProvider);

      // Phase 1: Offload JobModel construction + JSON serialization to
      // background isolate so the main UI thread stays responsive.
      // Pack schedule data as raw maps (sendable across isolates).
      final dueMaps = due.map((s) => {
        'id': s.id,
        'customerId': s.customerId,
        'serviceType': s.serviceType,
        'nextDueDate': s.nextDueDate.toIso8601String(),
        'notes': s.notes,
        'dayOfWeek': s.dayOfWeek,
        'dayOfMonth': s.dayOfMonth,
      }).toList();
      final jobsToWrite = await Isolate.run(() => _buildJobPayloads(
        scheduleData: dueMaps,
        userId: userId,
        batchId: batchId,
      ));
      debugPrint('[KS:RECURRING] Isolate built ${jobsToWrite.length} job payloads');

      // Phase 2: Write jobs to Hive in batches with yields
      const chunkSize = 20;
      final entries = jobsToWrite.entries.toList();
      for (int i = 0; i < entries.length; i += chunkSize) {
        final chunk = entries.sublist(i, (i + chunkSize).clamp(0, entries.length));
        for (final entry in chunk) {
          await jobsBox.put(entry.key, entry.value);
        }
        await jobsBox.flush();
        // Yield to event loop so the UI can process frames
        await Future.delayed(Duration.zero);
      }

      // Phase 3: Advance schedules (trigger second) in batches with yields
      for (int i = 0; i < due.length; i += chunkSize) {
        final chunk = due.sublist(i, (i + chunkSize).clamp(0, due.length));
        for (final schedule in chunk) {
          final advanced = _advanceNextDueDate(schedule);
          final updated = schedule.copyWith(nextDueDate: advanced, updatedAt: DateTime.now());
          await localDs.save(updated);
        }
        await Future.delayed(Duration.zero);
      }

      count = due.length;
      debugPrint('[KS:RECURRING] Generated $count jobs from batch $batchId');
    } catch (e) {
      debugPrint('[KS:RECURRING] Failed to generate jobs for batch $batchId: $e');
      // WAL remains — recovery hook replays on next startup
      await load();
      return 0;
    }

    // Phase 4: Mark WAL completed and clear
    await meta.put('pending_schedule_gen:$batchId', {
      'batch_id': batchId,
      'target_schedule_ids': due.map((s) => s.id).toList(),
      'state': 'completed',
      'created_at': DateTime.now().toIso8601String(),
    });
    await meta.delete('pending_schedule_gen:$batchId');
    await meta.flush();

    await load();
    return count;
  }

  /// Background-isolate entrypoint for Phase 1 job payload construction.
  /// Extracted as a static method so [Isolate.run] can invoke it.
  static Map<String, Map<String, dynamic>> _buildJobPayloads({
    required List<Map<String, dynamic>> scheduleData,
    required String userId,
    required String batchId,
  }) {
    final jobsToWrite = <String, Map<String, dynamic>>{};
    for (final data in scheduleData) {
      final jobId = const Uuid().v4();
      final createdAt = DateTime.now();
      final jobModel = JobModel(
        id: jobId,
        userId: userId,
        customerId: data['customerId'] as String,
        serviceType: data['serviceType'] as String? ?? '',
        jobDate: DateTime.tryParse(data['nextDueDate'] as String? ?? '') ?? DateTime.now(),
        location: null,
        notes: data['notes'] as String?,
        amountCharged: null,
        followUpSent: false,
        syncStatus: 'pending',
        isArchived: false,
        status: 'quoted',
        paymentStatus: 'unpaid',
        createdAt: createdAt.toIso8601String(),
        updatedAt: createdAt.toIso8601String(),
        isDeleted: false,
        subEntitiesSaved: false,
        generatedFromScheduleId: data['id'] as String?,
        generationBatchId: batchId,
      );
      jobsToWrite[jobId] = jobModel.toJson().cast<String, dynamic>();
    }
    return jobsToWrite;
  }
}

final recurringScheduleProvider = StateNotifierProvider<RecurringScheduleNotifier, AsyncValue<List<RecurringScheduleEntity>>>((ref) {
  final notifier = RecurringScheduleNotifier(ref);
  notifier.load();
  return notifier;
});

final dueSchedulesProvider = Provider.family<List<RecurringScheduleEntity>, String>((ref, _) {
  final schedules = ref.watch(recurringScheduleProvider).valueOrNull ?? [];
  return schedules.where((s) => s.isActive && s.isDue).toList();
});
