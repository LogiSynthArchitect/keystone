class ServiceTypeEntity {
  final String id;
  final String userId;
  final String name;
  final String slug;
  final String? description;
  final bool isDefault;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceTypeEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.slug,
    this.description,
    this.isDefault = false,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  ServiceTypeEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? slug,
    String? description,
    bool? isDefault,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceTypeEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
