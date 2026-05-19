class JobPartEntity {
  final String id;
  final String jobId;
  final String partName;
  final int? quantity;
  final int? unitPrice; // In pesewas
  final String? inventoryItemId;
  final DateTime createdAt;

  const JobPartEntity({
    required this.id,
    required this.jobId,
    required this.partName,
    this.quantity,
    this.unitPrice,
    this.inventoryItemId,
    required this.createdAt,
  });

  int get totalCost => (quantity ?? 0) * (unitPrice ?? 0);

  JobPartEntity copyWith({
    String? id,
    String? jobId,
    String? partName,
    int? quantity,
    int? unitPrice,
    String? inventoryItemId,
    DateTime? createdAt,
  }) => JobPartEntity(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    partName: partName ?? this.partName,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    inventoryItemId: inventoryItemId ?? this.inventoryItemId,
    createdAt: createdAt ?? this.createdAt,
  );
}
