import '../../domain/entities/service_type_entity.dart';

class ServiceTypeModel {
  final String id;
  final String userId;
  final String name;
  final String slug;
  final String? description;
  final bool isDefault;
  final bool isActive;
  final int displayOrder;
  final String createdAt;
  final String updatedAt;

  const ServiceTypeModel({
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

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) => ServiceTypeModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        displayOrder: (json['display_order'] as num? ?? 0).toInt(),
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'slug': slug,
        'description': description,
        'is_default': isDefault,
        'is_active': isActive,
        'display_order': displayOrder,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  ServiceTypeEntity toEntity() => ServiceTypeEntity(
        id: id,
        userId: userId,
        name: name,
        slug: slug,
        description: description,
        isDefault: isDefault,
        isActive: isActive,
        displayOrder: displayOrder,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory ServiceTypeModel.fromEntity(ServiceTypeEntity entity) => ServiceTypeModel(
        id: entity.id,
        userId: entity.userId,
        name: entity.name,
        slug: entity.slug,
        description: entity.description,
        isDefault: entity.isDefault,
        isActive: entity.isActive,
        displayOrder: entity.displayOrder,
        createdAt: entity.createdAt.toIso8601String(),
        updatedAt: entity.updatedAt.toIso8601String(),
      );
}
