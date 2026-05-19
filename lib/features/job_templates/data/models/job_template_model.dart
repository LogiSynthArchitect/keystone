import '../../domain/entities/job_template_entity.dart';

class JobTemplateModel {
  final String id;
  final String userId;
  final String name;
  final String serviceType;
  final String? notes;
  final List<dynamic> services;
  final List<dynamic> hardwareItems;
  final List<dynamic> parts;
  final String createdAt;
  final String updatedAt;

  const JobTemplateModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.serviceType,
    this.notes,
    this.services = const [],
    this.hardwareItems = const [],
    this.parts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobTemplateModel.fromJson(Map<String, dynamic> json) => JobTemplateModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    serviceType: json['service_type'] as String,
    notes: json['notes'] as String?,
    services: json['services_json'] as List<dynamic>? ?? [],
    hardwareItems: json['hardware_json'] as List<dynamic>? ?? [],
    parts: json['parts_json'] as List<dynamic>? ?? [],
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'service_type': serviceType,
    'notes': notes,
    'services_json': services,
    'hardware_json': hardwareItems,
    'parts_json': parts,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  JobTemplateEntity toEntity() => JobTemplateEntity(
    id: id,
    userId: userId,
    name: name,
    serviceType: serviceType,
    notes: notes,
    services: services.cast<Map<String, dynamic>>(),
    hardwareItems: hardwareItems.cast<Map<String, dynamic>>(),
    parts: parts.cast<Map<String, dynamic>>(),
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );

  factory JobTemplateModel.fromEntity(JobTemplateEntity entity) => JobTemplateModel(
    id: entity.id,
    userId: entity.userId,
    name: entity.name,
    serviceType: entity.serviceType,
    notes: entity.notes,
    services: entity.services,
    hardwareItems: entity.hardwareItems,
    parts: entity.parts,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
  );
}
