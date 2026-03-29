import '../../domain/entities/service_type_entity.dart';

class ServiceTypeModel {
  final String id;
  final String userId;
  final String name;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;

  const ServiceTypeModel({
    required this.id,
    required this.userId,
    required this.name,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) => ServiceTypeModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    isDefault: json['is_default'] as bool? ?? false,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'is_default': isDefault,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  ServiceTypeEntity toEntity() => ServiceTypeEntity(
    id: id,
    userId: userId,
    name: name,
    isDefault: isDefault,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );

  factory ServiceTypeModel.fromEntity(ServiceTypeEntity entity) => ServiceTypeModel(
    id: entity.id,
    userId: entity.userId,
    name: entity.name,
    isDefault: entity.isDefault,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
  );
}
