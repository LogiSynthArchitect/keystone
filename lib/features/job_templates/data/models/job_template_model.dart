import '../../domain/entities/job_template_entity.dart';
import '../../domain/entities/template_service_item.dart';
import '../../domain/entities/template_hardware_item.dart';
import '../../domain/entities/template_part_item.dart';
import '../../../../core/utils/forward_compatible.dart';

class JobTemplateModel {
  static const _kKnown = {'id', 'user_id', 'name', 'service_type', 'notes', 'services_json', 'hardware_json', 'parts_json', 'created_at', 'updated_at', 'is_deleted'};

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
  final bool isDeleted;
  final Map<String, dynamic> preserved;

  JobTemplateModel({
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
    this.isDeleted = false,
    this.preserved = const {},
  });

  factory JobTemplateModel.fromJson(Map<String, dynamic> json) =>
      JobTemplateModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: (json['name'] as String?) ?? '',
        serviceType: (json['service_type'] as String?) ?? '',
        notes: json['notes'] as String?,
        services: json['services_json'] as List<dynamic>? ?? (json['services'] as List<dynamic>? ?? []),
        hardwareItems: json['hardware_json'] as List<dynamic>? ?? (json['hardwareItems'] as List<dynamic>? ?? []),
        parts: json['parts_json'] as List<dynamic>? ?? (json['parts'] as List<dynamic>? ?? []),
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        isDeleted: json['is_deleted'] as bool? ?? false,
        preserved: ForwardCompatible.extractPreserved(json, _kKnown),
      );

  Map<String, dynamic> toJson() {
    final fields = <String, dynamic>{
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
      if (isDeleted) 'is_deleted': true,
    };
    return ForwardCompatible.buildJson(preserved, fields);
  }

  JobTemplateEntity toEntity() => JobTemplateEntity(
    id: id,
    userId: userId,
    name: name,
    serviceType: serviceType,
    notes: notes,
    services: services
        .map((e) => TemplateServiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    hardwareItems: hardwareItems
        .map((e) => TemplateHardwareItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    parts: parts
        .map((e) => TemplatePartItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
    isDeleted: isDeleted,
  );

  factory JobTemplateModel.fromEntity(JobTemplateEntity entity) =>
      JobTemplateModel(
        id: entity.id,
        userId: entity.userId,
        name: entity.name,
        serviceType: entity.serviceType,
        notes: entity.notes,
        services: entity.services.map((e) => e.toJson()).toList(),
        hardwareItems: entity.hardwareItems.map((e) => e.toJson()).toList(),
        parts: entity.parts.map((e) => e.toJson()).toList(),
        createdAt: entity.createdAt.toIso8601String(),
        updatedAt: entity.updatedAt.toIso8601String(),
        isDeleted: entity.isDeleted,
      );

  JobTemplateModel copyWith({bool? isDeleted, Map<String, dynamic>? preserved}) => JobTemplateModel(
    id: id,
    userId: userId,
    name: name,
    serviceType: serviceType,
    notes: notes,
    services: services,
    hardwareItems: hardwareItems,
    parts: parts,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    preserved: preserved ?? this.preserved,
  );
}
