import '../../domain/entities/job_hardware_entity.dart';

class JobHardwareModel {
  final String id;
  final String jobId;
  final String? domain;
  final String? category;
  final String? brand;
  final String? model;
  final String? keySpec;
  final String? material;
  final String? finish;
  final String? dimensions;
  final int quantity;
  final int? unitSalePrice;
  final int? unitCostPrice;
  final String? notes;
  final int sortOrder;
  final String createdAt;

  const JobHardwareModel({
    required this.id,
    required this.jobId,
    this.domain,
    this.category,
    this.brand,
    this.model,
    this.keySpec,
    this.material,
    this.finish,
    this.dimensions,
    this.quantity = 1,
    this.unitSalePrice,
    this.unitCostPrice,
    this.notes,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory JobHardwareModel.fromJson(Map<String, dynamic> json) => JobHardwareModel(
    id: json['id'],
    jobId: json['job_id'],
    domain: json['domain'] as String?,
    category: json['category'] as String?,
    brand: json['brand'] as String?,
    model: json['model'] as String?,
    keySpec: json['key_spec'] as String?,
    material: json['material'] as String?,
    finish: json['finish'] as String?,
    dimensions: json['dimensions'] as String?,
    quantity: json['quantity'] as int? ?? 1,
    unitSalePrice: json['unit_sale_price'] as int?,
    unitCostPrice: json['unit_cost_price'] as int?,
    notes: json['notes'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
    createdAt: json['created_at'],
  );

  factory JobHardwareModel.fromEntity(JobHardwareEntity entity) => JobHardwareModel(
    id: entity.id,
    jobId: entity.jobId,
    domain: entity.domain,
    category: entity.category,
    brand: entity.brand,
    model: entity.model,
    keySpec: entity.keySpec,
    material: entity.material,
    finish: entity.finish,
    dimensions: entity.dimensions,
    quantity: entity.quantity,
    unitSalePrice: entity.unitSalePrice,
    unitCostPrice: entity.unitCostPrice,
    notes: entity.notes,
    sortOrder: entity.sortOrder,
    createdAt: entity.createdAt.toIso8601String(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'job_id': jobId,
    'domain': domain,
    'category': category,
    'brand': brand,
    'model': model,
    'key_spec': keySpec,
    'material': material,
    'finish': finish,
    'dimensions': dimensions,
    'quantity': quantity,
    'unit_sale_price': unitSalePrice,
    'unit_cost_price': unitCostPrice,
    'notes': notes,
    'sort_order': sortOrder,
    'created_at': createdAt,
  };

  JobHardwareEntity toEntity() => JobHardwareEntity(
    id: id,
    jobId: jobId,
    domain: domain,
    category: category,
    brand: brand,
    model: model,
    keySpec: keySpec,
    material: material,
    finish: finish,
    dimensions: dimensions,
    quantity: quantity,
    unitSalePrice: unitSalePrice,
    unitCostPrice: unitCostPrice,
    notes: notes,
    sortOrder: sortOrder,
    createdAt: DateTime.parse(createdAt),
  );
}

