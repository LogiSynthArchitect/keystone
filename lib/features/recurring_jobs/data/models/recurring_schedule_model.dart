import '../../domain/entities/recurring_schedule_entity.dart';

class RecurringScheduleModel {
  final String id;
  final String userId;
  final String customerId;
  final String? customerName;
  final String serviceType;
  final String? serviceTypeId;
  final String intervalType;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final String nextDueDate;
  final bool isActive;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  const RecurringScheduleModel({
    required this.id,
    required this.userId,
    required this.customerId,
    this.customerName,
    required this.serviceType,
    this.serviceTypeId,
    required this.intervalType,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.nextDueDate,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  factory RecurringScheduleModel.fromJson(Map<String, dynamic> json) =>
      RecurringScheduleModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        customerId: json['customer_id'] as String,
        customerName: json['customer_name'] as String?,
        serviceType: (json['service_type'] as String?) ?? '',
        serviceTypeId: json['service_type_id'] as String?,
        intervalType: (json['interval_type'] as String?) ?? '',
        dayOfWeek: json['day_of_week'] as int?,
        dayOfMonth: json['day_of_month'] as int?,
        nextDueDate: (json['next_due_date'] as String?) ?? '',
        isActive: json['is_active'] as bool? ?? true,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        syncStatus: json['sync_status'] as String? ?? 'synced',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'customer_id': customerId,
    if (customerName != null) 'customer_name': customerName,
    'service_type': serviceType,
    if (serviceTypeId != null) 'service_type_id': serviceTypeId,
    'interval_type': intervalType,
    if (dayOfWeek != null) 'day_of_week': dayOfWeek,
    if (dayOfMonth != null) 'day_of_month': dayOfMonth,
    'next_due_date': nextDueDate,
    'is_active': isActive,
    if (notes != null) 'notes': notes,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus,
  };

  RecurringScheduleEntity toEntity() => RecurringScheduleEntity(
    id: id,
    userId: userId,
    customerId: customerId,
    customerName: customerName ?? '',
    serviceType: serviceType,
    serviceTypeId: serviceTypeId,
    intervalType: intervalType,
    dayOfWeek: dayOfWeek,
    dayOfMonth: dayOfMonth,
    nextDueDate: DateTime.parse(nextDueDate),
    isActive: isActive,
    notes: notes,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );

  factory RecurringScheduleModel.fromEntity(RecurringScheduleEntity entity) =>
      RecurringScheduleModel(
        id: entity.id,
        userId: entity.userId,
        customerId: entity.customerId,
        customerName: entity.customerName,
        serviceType: entity.serviceType,
        serviceTypeId: entity.serviceTypeId,
        intervalType: entity.intervalType,
        dayOfWeek: entity.dayOfWeek,
        dayOfMonth: entity.dayOfMonth,
        nextDueDate: entity.nextDueDate.toIso8601String(),
        isActive: entity.isActive,
        notes: entity.notes,
        createdAt: entity.createdAt.toIso8601String(),
        updatedAt: entity.updatedAt.toIso8601String(),
        syncStatus: 'synced',
      );
}
