import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../../domain/entities/recurring_schedule_entity.dart';
import '../models/recurring_schedule_model.dart';

class RecurringScheduleLocalDatasource {
  Box get _box => HiveService.recurringSchedules;

  Future<List<RecurringScheduleEntity>> getAll() async {
    return _box.values
        .map((json) => _fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<List<RecurringScheduleEntity>> getPending() async {
    return _box.values
        .map((json) => _fromJson(Map<String, dynamic>.from(json)))
        .where((e) => _syncStatus(Map<String, dynamic>.from(_box.get(e.id) as Map)) == 'pending')
        .toList();
  }

  Future<void> save(RecurringScheduleEntity entity) async {
    await _box.put(entity.id, _toJson(entity));
    await _box.flush();
  }

  Future<void> markSynced(RecurringScheduleEntity entity) async {
    final json = _toJson(entity);
    json['sync_status'] = 'synced';
    await _box.put(entity.id, json);
    await _box.flush();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Map<String, dynamic> _toJson(RecurringScheduleEntity e) => {
    'id': e.id,
    'user_id': e.userId,
    'customer_id': e.customerId,
    'customer_name': e.customerName,
    'service_type': e.serviceType,
    'service_type_id': e.serviceTypeId,
    'interval_type': e.intervalType,
    'day_of_week': e.dayOfWeek,
    'day_of_month': e.dayOfMonth,
    'next_due_date': e.nextDueDate.toIso8601String(),
    'is_active': e.isActive,
    'notes': e.notes,
    'created_at': e.createdAt.toIso8601String(),
    'updated_at': e.updatedAt.toIso8601String(),
    'sync_status': 'pending',
  };

  String _syncStatus(Map<String, dynamic> j) => j['sync_status'] as String? ?? 'synced';

  RecurringScheduleEntity _fromJson(Map<String, dynamic> j) => RecurringScheduleEntity(
    id: j['id'] as String,
    userId: j['user_id'] as String,
    customerId: j['customer_id'] as String,
    customerName: (j['customer_name'] as String?) ?? '',
    serviceType: j['service_type'] as String,
    serviceTypeId: j['service_type_id'] as String?,
    intervalType: j['interval_type'] as String,
    dayOfWeek: j['day_of_week'] as int?,
    dayOfMonth: j['day_of_month'] as int?,
    nextDueDate: DateTime.parse(j['next_due_date'] as String),
    isActive: j['is_active'] as bool? ?? true,
    notes: j['notes'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );
}
