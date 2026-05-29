import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../../../core/utils/forward_compatible.dart';

class InventoryItemModel {
  static const _kKnown = {
    'id', 'user_id', 'item_type', 'name', 'attributes', 'brand', 'model',
    'key_spec', 'material', 'finish', 'dimensions', 'default_cost_price',
    'default_sale_price', 'quantity', 'low_stock_threshold', 'location',
    'is_archived', 'is_auto_cogs', 'snooze_low_stock_until', 'cover_image_url',
    'applied_transaction_ids', 'created_at', 'updated_at', 'sync_status',
    'correction_fields', 'updated_by', 'search_index', 'is_deleted',
  };

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
  final List<String> appliedTransactionIds;
  final String createdAt;
  final String updatedAt;
  final SyncStatus syncStatus;
  final List<String> correctionFields;
  final String? updatedBy;
  final String? searchIndex;
  final bool isDeleted;
  final Map<String, dynamic> preserved;

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
    this.appliedTransactionIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.correctionFields = const [],
    this.updatedBy,
    this.searchIndex,
    this.isDeleted = false,
    this.preserved = const {},
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
    appliedTransactionIds: json['applied_transaction_ids'] != null
        ? List<String>.from(json['applied_transaction_ids'] as List)
        : [],
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
    syncStatus: SyncStatus.values.firstWhere(
      (e) => e.name == (json['sync_status'] as String? ?? 'synced'),
      orElse: () => SyncStatus.synced,
    ),
    correctionFields: json['correction_fields'] != null
        ? List<String>.from(json['correction_fields'] as List)
        : [],
    updatedBy: json['updated_by'] as String?,
    searchIndex: json['search_index'] as String?,
    isDeleted: json['is_deleted'] as bool? ?? false,
    preserved: ForwardCompatible.extractPreserved(json, _kKnown),
  );

  Map<String, dynamic> toJson() {
    final fields = <String, dynamic>{
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
      if (appliedTransactionIds.isNotEmpty) 'applied_transaction_ids': appliedTransactionIds,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus.name,
      if (correctionFields.isNotEmpty) 'correction_fields': correctionFields,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (searchIndex != null) 'search_index': searchIndex,
      if (isDeleted) 'is_deleted': true,
    };
    return ForwardCompatible.buildJson(preserved, fields);
  }

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
    appliedTransactionIds: appliedTransactionIds,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
    syncStatus: syncStatus,
    correctionFields: correctionFields,
    updatedBy: updatedBy,
    searchIndex: searchIndex,
    isDeleted: isDeleted,
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
    appliedTransactionIds: entity.appliedTransactionIds,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
    syncStatus: entity.syncStatus,
    correctionFields: entity.correctionFields,
    updatedBy: entity.updatedBy,
    searchIndex: entity.searchIndex,
    isDeleted: entity.isDeleted,
  );

  InventoryItemModel copyWith({
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
    String? snoozeLowStockUntil,
    String? coverImageUrl,
    List<String>? appliedTransactionIds,
    String? createdAt,
    String? updatedAt,
    SyncStatus? syncStatus,
    List<String>? correctionFields,
    String? updatedBy,
    String? searchIndex,
    bool? isDeleted,
    Map<String, dynamic>? preserved,
  }) {
    return InventoryItemModel(
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
      appliedTransactionIds: appliedTransactionIds ?? this.appliedTransactionIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      correctionFields: correctionFields ?? this.correctionFields,
      updatedBy: updatedBy ?? this.updatedBy,
      searchIndex: searchIndex ?? this.searchIndex,
      isDeleted: isDeleted ?? this.isDeleted,
      preserved: preserved ?? this.preserved,
    );
  }
}
