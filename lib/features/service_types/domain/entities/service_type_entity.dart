class ServiceTypeEntity {
  final String id;
  final String userId;
  final String name;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceTypeEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  ServiceTypeEntity copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceTypeEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
