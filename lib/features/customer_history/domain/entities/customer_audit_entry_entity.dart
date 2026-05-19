class CustomerAuditEntryEntity {
  final String id;
  final String customerId;
  final String fieldName;      // 'fullName', 'phoneNumber', 'location', etc.
  final String? oldValue;
  final String? newValue;
  final String userId;         // Who made the change
  final DateTime createdAt;

  const CustomerAuditEntryEntity({
    required this.id,
    required this.customerId,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.userId,
    required this.createdAt,
  });

  CustomerAuditEntryEntity copyWith({
    String? id,
    String? customerId,
    String? fieldName,
    String? oldValue,
    String? newValue,
    String? userId,
    DateTime? createdAt,
  }) => CustomerAuditEntryEntity(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    fieldName: fieldName ?? this.fieldName,
    oldValue: oldValue ?? this.oldValue,
    newValue: newValue ?? this.newValue,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
  );
}
