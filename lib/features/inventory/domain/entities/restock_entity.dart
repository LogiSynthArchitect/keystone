class RestockEntity {
  final String id;
  final String itemId;
  final String userId;
  final int quantity;
  final int unitCost;
  final int totalCost;
  final String? vendor;
  final String? supplierPhone;
  final String? notes;
  final DateTime createdAt;

  const RestockEntity({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.vendor,
    this.supplierPhone,
    this.notes,
    required this.createdAt,
  });

  RestockEntity copyWith({
    String? id,
    String? itemId,
    String? userId,
    int? quantity,
    int? unitCost,
    int? totalCost,
    String? vendor,
    String? supplierPhone,
    String? notes,
    DateTime? createdAt,
  }) {
    return RestockEntity(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      vendor: vendor ?? this.vendor,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
