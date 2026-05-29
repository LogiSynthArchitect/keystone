class ServiceTypeEntity {
  final String id;
  final String userId;
  final String name;
  final bool isDefault;
  final String category;
  final String iconName;
  final int? defaultPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> correctionFields;
  final String updatedBy;
  final bool isDeleted;

  const ServiceTypeEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.iconName,
    this.isDefault = false,
    this.defaultPrice,
    required this.createdAt,
    required this.updatedAt,
    this.correctionFields = const [],
    this.updatedBy = 'mobile',
    this.isDeleted = false,
  });

  ServiceTypeEntity copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isDefault,
    String? category,
    String? iconName,
    int? defaultPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? correctionFields,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return ServiceTypeEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      correctionFields: correctionFields ?? this.correctionFields,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
