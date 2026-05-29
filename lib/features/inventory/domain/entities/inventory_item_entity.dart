import '../../../../core/constants/app_enums.dart';

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
  final List<String> appliedTransactionIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final List<String> correctionFields;
  final String? updatedBy;
  final String? searchIndex;
  final bool isDeleted;

  bool get isSynced => syncStatus == SyncStatus.synced;
  bool get isPending => syncStatus == SyncStatus.pending;

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
    this.appliedTransactionIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.correctionFields = const [],
    this.updatedBy,
    this.searchIndex,
    this.isDeleted = false,
  });

  /// Build a deduplicated lowercase search index from key fields.
  /// Format: "name brand model location category attr1 attr2 ..."
  static String? buildSearchIndex({
    required String name,
    String? brand,
    String? model,
    String? location,
    String? keySpec,
    String? material,
    String? finish,
    String? dimensions,
    required InventoryItemCategory category,
    Map<String, dynamic> attributes = const {},
  }) {
    final parts = <String>[
      name,
      if (brand != null) brand,
      if (model != null) model,
      if (location != null) location,
      category.displayName,
      if (keySpec != null) keySpec,
      if (material != null) material,
      if (finish != null) finish,
      if (dimensions != null) dimensions,
      ...attributes.values.map((v) => v.toString()),
    ];
    final words = parts
        .expand((s) => s.toLowerCase().split(RegExp(r'\s+')))
        .where((w) => w.isNotEmpty)
        .toSet()
        .join(' ');
    return words.isNotEmpty ? words : null;
  }

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
    List<String>? appliedTransactionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    List<String>? correctionFields,
    String? updatedBy,
    String? searchIndex,
    bool? isDeleted,
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
      appliedTransactionIds: appliedTransactionIds ?? this.appliedTransactionIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      correctionFields: correctionFields ?? this.correctionFields,
      updatedBy: updatedBy ?? this.updatedBy,
      searchIndex: searchIndex ?? this.searchIndex,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
