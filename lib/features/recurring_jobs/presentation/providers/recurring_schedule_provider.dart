import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../data/datasources/recurring_schedule_local_datasource.dart';
import '../../domain/entities/recurring_schedule_entity.dart';

final recurringScheduleLocalDatasourceProvider = Provider<RecurringScheduleLocalDatasource>((ref) => RecurringScheduleLocalDatasource());

class RecurringScheduleNotifier extends StateNotifier<AsyncValue<List<RecurringScheduleEntity>>> {
  final Ref _ref;
  RecurringScheduleNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> load() async {
    try {
      final items = await _ref.read(recurringScheduleLocalDatasourceProvider).getAll();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add({
    required String customerId,
    required String customerName,
    required String serviceType,
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
