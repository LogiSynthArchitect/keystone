import '../../domain/entities/stock_adjustment_entity.dart';

class StockAdjustmentModel {
  final String id;
  final String itemId;
  final String userId;
  final String adjustmentType;
  final int quantityChange;
  final int quantityAfter;
  final String? reason;
  final String? referenceType;
  final String? referenceId;
  final String createdAt;

  const StockAdjustmentModel({
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

  factory StockAdjustmentModel.fromJson(Map<String, dynamic> json) => StockAdjustmentModel(
    id: json['id'] as String,
    itemId: json['item_id'] as String,
    userId: json['user_id'] as String,
    adjustmentType: json['adjustment_type'] as String,
    quantityChange: json['quantity_change'] as int,
    quantityAfter: json['quantity_after'] as int,
    reason: json['reason'] as String?,
    referenceType: json['reference_type'] as String?,
    referenceId: json['reference_id'] as String?,
    createdAt: json['created_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_id': itemId,
    'user_id': userId,
    'adjustment_type': adjustmentType,
    'quantity_change': quantityChange,
    'quantity_after': quantityAfter,
    'reason': reason,
    'reference_type': referenceType,
    'reference_id': referenceId,
    'created_at': createdAt,
  };

  StockAdjustmentEntity toEntity() => StockAdjustmentEntity(
    id: id,
    itemId: itemId,
    userId: userId,
    adjustmentType: adjustmentType,
    quantityChange: quantityChange,
    quantityAfter: quantityAfter,
    reason: reason,
    referenceType: referenceType,
    referenceId: referenceId,
    createdAt: DateTime.parse(createdAt),
  );

  factory StockAdjustmentModel.fromEntity(StockAdjustmentEntity entity) => StockAdjustmentModel(
    id: entity.id,
    itemId: entity.itemId,
    userId: entity.userId,
    adjustmentType: entity.adjustmentType,
    quantityChange: entity.quantityChange,
    quantityAfter: entity.quantityAfter,
    reason: entity.reason,
    referenceType: entity.referenceType,
    referenceId: entity.referenceId,
    createdAt: entity.createdAt.toIso8601String(),
  );
}
