class JobServiceEntity {
  final String id;
  final String jobId;
  final String serviceType;
  final int quantity;
  final int? unitPrice;
  final String? domain;
  final String? notes;
  final int sortOrder;
  final DateTime createdAt;

  const JobServiceEntity({
    required this.id,
    required this.jobId,
    required this.serviceType,
    this.quantity = 1,
    this.unitPrice,
    this.domain,
    this.notes,
    this.sortOrder = 0,
    required this.createdAt,
  });

  int get totalPrice => quantity * (unitPrice ?? 0);

  JobServiceEntity copyWith({
    String? id,
    String? jobId,
    String? serviceType,
    int? quantity,
    int? unitPrice,
    String? domain,
    String? notes,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return JobServiceEntity(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      serviceType: serviceType ?? this.serviceType,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      domain: domain ?? this.domain,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

