class StockAdjustmentEntity {
  final String id;
  final String itemId;
  final String userId;
  final String adjustmentType;
  final int quantityChange;
  final int quantityAfter;
  final String? reason;
  final String? referenceType;
  final String? referenceId;
  final DateTime createdAt;

  const StockAdjustmentEntity({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.adjustmentType,
    required this.quantityChange,
    required this.quantityAfter,
    this.reason,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  StockAdjustmentEntity copyWith({
    String? id,
    String? itemId,
    String? userId,
    String? adjustmentType,
    int? quantityChange,
    int? quantityAfter,
    String? reason,
    String? referenceType,
    String? referenceId,
    DateTime? createdAt,
  }) {
    return StockAdjustmentEntity(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      adjustmentType: adjustmentType ?? this.adjustmentType,
      quantityChange: quantityChange ?? this.quantityChange,
      quantityAfter: quantityAfter ?? this.quantityAfter,
      reason: reason ?? this.reason,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
