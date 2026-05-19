class JobHardwareEntity {
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
  final DateTime createdAt;

  const JobHardwareEntity({
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

  int get totalSalePrice => quantity * (unitSalePrice ?? 0);
  int get totalCostPrice => quantity * (unitCostPrice ?? 0);
  bool get hasCost => unitCostPrice != null;
  int get grossProfit => totalSalePrice - totalCostPrice;

  JobHardwareEntity copyWith({
    String? id,
    String? jobId,
    String? domain,
    String? category,
    String? brand,
    String? model,
    String? keySpec,
    String? material,
    String? finish,
    String? dimensions,
    int? quantity,
    int? unitSalePrice,
    int? unitCostPrice,
    String? notes,
    int? sortOrder,
    DateTime? createdAt,
  }) => JobHardwareEntity(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    domain: domain ?? this.domain,
    category: category ?? this.category,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    keySpec: keySpec ?? this.keySpec,
    material: material ?? this.material,
    finish: finish ?? this.finish,
    dimensions: dimensions ?? this.dimensions,
    quantity: quantity ?? this.quantity,
    unitSalePrice: unitSalePrice ?? this.unitSalePrice,
    unitCostPrice: unitCostPrice ?? this.unitCostPrice,
    notes: notes ?? this.notes,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
}

