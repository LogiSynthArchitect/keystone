enum InventoryItemCategory {
  key,
  lock,
  automotive,
  electronic,
  safe,
  consumable;

  String get displayName {
    switch (this) {
      case InventoryItemCategory.key: return 'KEY';
      case InventoryItemCategory.lock: return 'LOCK';
      case InventoryItemCategory.automotive: return 'AUTO';
      case InventoryItemCategory.electronic: return 'ELECTRONIC';
      case InventoryItemCategory.safe: return 'SAFE';
      case InventoryItemCategory.consumable: return 'CONSUMABLE';
    }
  }

  String get dbValue => name;

  static InventoryItemCategory fromDb(String value) {
    return InventoryItemCategory.values.firstWhere(
      (c) => c.dbValue == value,
      orElse: () => InventoryItemCategory.consumable,
    );
  }
}

class InventoryItemEntity {
  final String id;
  final String userId;
  final InventoryItemCategory category;
  final String name;
  final Map<String, dynamic> attributes;
  // Legacy fields — kept for backward compat with existing data
  final String? brand;
  final String? model;
  final String? keySpec;
  final String? material;
  final String? finish;
  final String? dimensions;
  final int? defaultCostPrice;
  final int? defaultSalePrice;
  final int quantity;
  final int? lowStockThreshold;
  final String? location;
  final bool isArchived;
  final bool isAutoCogs;
  final DateTime? snoozeLowStockUntil;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItemEntity({
    required this.id,
    required this.userId,
    required this.category,
    required this.name,
    this.attributes = const {},
    this.brand,
    this.model,
    this.keySpec,
    this.material,
    this.finish,
    this.dimensions,
    this.defaultCostPrice,
    this.defaultSalePrice,
    this.quantity = 0,
    this.lowStockThreshold,
    this.location,
    this.isArchived = false,
    this.isAutoCogs = false,
    this.snoozeLowStockUntil,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => lowStockThreshold != null && quantity <= lowStockThreshold!;

  bool get isLowStockSnoozed => snoozeLowStockUntil != null && snoozeLowStockUntil!.isAfter(DateTime.now());

  InventoryItemEntity copyWith({
    String? id,
    String? userId,
    InventoryItemCategory? category,
    String? name,
    Map<String, dynamic>? attributes,
    String? brand,
    String? model,
    String? keySpec,
    String? material,
    String? finish,
    String? dimensions,
    int? defaultCostPrice,
    int? defaultSalePrice,
    int? quantity,
    int? lowStockThreshold,
    String? location,
    bool? isArchived,
    bool? isAutoCogs,
    DateTime? snoozeLowStockUntil,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItemEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      name: name ?? this.name,
      attributes: attributes ?? this.attributes,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      keySpec: keySpec ?? this.keySpec,
      material: material ?? this.material,
      finish: finish ?? this.finish,
      dimensions: dimensions ?? this.dimensions,
      defaultCostPrice: defaultCostPrice ?? this.defaultCostPrice,
      defaultSalePrice: defaultSalePrice ?? this.defaultSalePrice,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      location: location ?? this.location,
      isArchived: isArchived ?? this.isArchived,
      isAutoCogs: isAutoCogs ?? this.isAutoCogs,
      snoozeLowStockUntil: snoozeLowStockUntil ?? this.snoozeLowStockUntil,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
