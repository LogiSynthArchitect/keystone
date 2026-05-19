import '../../domain/entities/restock_entity.dart';

class RestockModel {
  final String id;
  final String itemId;
  final String userId;
  final int quantity;
  final int unitCost;
  final int totalCost;
  final String? vendor;
  final String? supplierPhone;
  final String? notes;
  final String createdAt;

  const RestockModel({
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

  factory RestockModel.fromJson(Map<String, dynamic> json) => RestockModel(
    id: json['id'] as String,
    itemId: json['item_id'] as String,
    userId: json['user_id'] as String,
    quantity: json['quantity'] as int,
    unitCost: json['unit_cost'] as int,
    totalCost: json['total_cost'] as int,
    vendor: json['vendor'] as String?,
    supplierPhone: json['supplier_phone'] as String?,
    notes: json['notes'] as String?,
    createdAt: json['created_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_id': itemId,
    'user_id': userId,
    'quantity': quantity,
    'unit_cost': unitCost,
    'total_cost': totalCost,
    'vendor': vendor,
    if (supplierPhone != null) 'supplier_phone': supplierPhone,
    'notes': notes,
    'created_at': createdAt,
  };

  RestockEntity toEntity() => RestockEntity(
    id: id,
    itemId: itemId,
    userId: userId,
    quantity: quantity,
    unitCost: unitCost,
    totalCost: totalCost,
    vendor: vendor,
    supplierPhone: supplierPhone,
    notes: notes,
    createdAt: DateTime.parse(createdAt),
  );

  factory RestockModel.fromEntity(RestockEntity entity) => RestockModel(
    id: entity.id,
    itemId: entity.itemId,
    userId: entity.userId,
    quantity: entity.quantity,
    unitCost: entity.unitCost,
    totalCost: entity.totalCost,
    vendor: entity.vendor,
    supplierPhone: entity.supplierPhone,
    notes: entity.notes,
    createdAt: entity.createdAt.toIso8601String(),
  );
}
