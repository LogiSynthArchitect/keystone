import '../../domain/entities/inventory_item_entity.dart';

class InventoryItemModel {
  final String id;
  final String userId;
  final InventoryItemCategory category;
  final String name;
  final Map<String, dynamic> attributes;
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
  final String? snoozeLowStockUntil;
  final String? coverImageUrl;
  final String createdAt;
  final String updatedAt;

  const InventoryItemModel({
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

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) => InventoryItemModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    category: InventoryItemCategory.fromDb(json['item_type'] as String),
    name: json['name'] as String,
    attributes: json['attributes'] != null
        ? Map<String, dynamic>.from(json['attributes'] as Map)
        : <String, dynamic>{},
    brand: json['brand'] as String?,
    model: json['model'] as String?,
    keySpec: json['key_spec'] as String?,
    material: json['material'] as String?,
    finish: json['finish'] as String?,
    dimensions: json['dimensions'] as String?,
    defaultCostPrice: json['default_cost_price'] as int?,
    defaultSalePrice: json['default_sale_price'] as int?,
    quantity: json['quantity'] as int? ?? 0,
    lowStockThreshold: json['low_stock_threshold'] as int?,
    location: json['location'] as String?,
    isArchived: json['is_archived'] as bool? ?? false,
    isAutoCogs: json['is_auto_cogs'] as bool? ?? false,
    snoozeLowStockUntil: json['snooze_low_stock_until'] as String?,
    coverImageUrl: json['cover_image_url'] as String?,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'item_type': category.dbValue,
    'name': name,
    'attributes': attributes,
    'brand': brand,
    'model': model,
    'key_spec': keySpec,
    'material': material,
    'finish': finish,
    'dimensions': dimensions,
    'default_cost_price': defaultCostPrice,
    'default_sale_price': defaultSalePrice,
    'quantity': quantity,
    'low_stock_threshold': lowStockThreshold,
    'location': location,
    'is_archived': isArchived,
    'is_auto_cogs': isAutoCogs,
    if (snoozeLowStockUntil != null) 'snooze_low_stock_until': snoozeLowStockUntil,
    'cover_image_url': coverImageUrl,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  InventoryItemEntity toEntity() => InventoryItemEntity(
    id: id,
    userId: userId,
    category: category,
    name: name,
    attributes: attributes,
    brand: brand,
    model: model,
    keySpec: keySpec,
    material: material,
    finish: finish,
    dimensions: dimensions,
    defaultCostPrice: defaultCostPrice,
    defaultSalePrice: defaultSalePrice,
    quantity: quantity,
    lowStockThreshold: lowStockThreshold,
    location: location,
    isArchived: isArchived,
    isAutoCogs: isAutoCogs,
    snoozeLowStockUntil: snoozeLowStockUntil != null ? DateTime.parse(snoozeLowStockUntil!) : null,
    coverImageUrl: coverImageUrl,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );

  factory InventoryItemModel.fromEntity(InventoryItemEntity entity) => InventoryItemModel(
    id: entity.id,
    userId: entity.userId,
    category: entity.category,
    name: entity.name,
    attributes: entity.attributes,
    brand: entity.brand,
    model: entity.model,
    keySpec: entity.keySpec,
    material: entity.material,
    finish: entity.finish,
    dimensions: entity.dimensions,
    defaultCostPrice: entity.defaultCostPrice,
    defaultSalePrice: entity.defaultSalePrice,
    quantity: entity.quantity,
    lowStockThreshold: entity.lowStockThreshold,
    location: entity.location,
    isArchived: entity.isArchived,
    isAutoCogs: entity.isAutoCogs,
    snoozeLowStockUntil: entity.snoozeLowStockUntil?.toIso8601String(),
    coverImageUrl: entity.coverImageUrl,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
  );
}
