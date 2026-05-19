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

  const ServiceTypeEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.isDefault = false,
    this.category = 'General',
    this.iconName = 'tools',
    this.defaultPrice,
    required this.createdAt,
    required this.updatedAt,
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
    );
  }
}
