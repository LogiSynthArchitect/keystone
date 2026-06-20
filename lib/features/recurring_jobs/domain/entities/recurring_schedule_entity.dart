class RecurringScheduleEntity {
  final String id;
  final String userId;
  final String customerId;
  final String customerName;
  final String serviceType;
  final String? serviceTypeId; // FK to service_types.id for name-drift resilience
  final String intervalType;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final DateTime nextDueDate;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringScheduleEntity({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.customerName,
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
  });

  RecurringScheduleEntity copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? customerName,
    String? serviceType,
    String? serviceTypeId,
    String? intervalType,
    int? dayOfWeek,
    int? dayOfMonth,
    DateTime? nextDueDate,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringScheduleEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      serviceType: serviceType ?? this.serviceType,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      intervalType: intervalType ?? this.intervalType,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get intervalLabel {
    switch (intervalType) {
      case 'weekly': return 'Every week';
      case 'monthly': return 'Every month';
      case 'quarterly': return 'Every quarter';
      case 'yearly': return 'Every year';
      default: return intervalType;
    }
  }

  /// Whether the schedule is due for job generation as of today.
  /// Uses date-level comparison (ignores time-of-day) to stay correct
  /// across device timezone changes. All dates use local-midnight semantics.
  bool get isDue {
    final now = DateTime.now();
    return nextDueDate.year < now.year ||
        (nextDueDate.year == now.year && nextDueDate.month < now.month) ||
        (nextDueDate.year == now.year && nextDueDate.month == now.month && nextDueDate.day <= now.day);
  }
}
