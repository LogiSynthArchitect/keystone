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
  DateTime _advanceNextDueDate(RecurringScheduleEntity schedule) {
    final next = schedule.nextDueDate;
    switch (schedule.intervalType) {
      case 'weekly':   return next.add(const Duration(days: 7));
      case 'monthly':  return DateTime(next.year, next.month + 1, next.day);
      case 'quarterly': return DateTime(next.year, next.month + 3, next.day);
      case 'yearly':   return DateTime(next.year + 1, next.month, next.day);
      default:         return next.add(const Duration(days: 30));
    }
  }

  /// Generate jobs for all due schedules, advance their nextDueDate.
  /// Returns the number of jobs created.
  Future<int> generateDueJobs() async {
    final items = state.valueOrNull ?? [];
    final due = items.where((s) => s.isActive && s.isDue).toList();
    if (due.isEmpty) return 0;

    final userId = _ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return 0;

    int count = 0;
    final jobsBox = HiveService.jobs;
    final localDs = _ref.read(recurringScheduleLocalDatasourceProvider);

    for (final schedule in due) {
      try {
        final jobId = const Uuid().v4();
        final jobModel = JobModel(
          id: jobId,
          userId: userId,
          customerId: schedule.customerId,
          serviceType: schedule.serviceType,
          jobDate: schedule.nextDueDate,
          location: null,
          notes: schedule.notes,
          amountCharged: null,
          followUpSent: false,
          syncStatus: 'pending',
          isArchived: false,
          status: 'quoted',
          paymentStatus: 'unpaid',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          isDeleted: false,
          subEntitiesSaved: false,
        );
        await jobsBox.put(jobId, jobModel.toJson().cast<String, dynamic>());
        await jobsBox.flush();

        // Advance nextDueDate
        final advanced = _advanceNextDueDate(schedule);
        final updated = schedule.copyWith(nextDueDate: advanced, updatedAt: DateTime.now());
        await localDs.save(updated);

        count++;
        debugPrint('[KS:RECURRING] Generated job $jobId from schedule ${schedule.id}');
      } catch (e) {
        debugPrint('[KS:RECURRING] Failed to generate job for ${schedule.id}: $e');
      }
    }

    await load();
    return count;
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
