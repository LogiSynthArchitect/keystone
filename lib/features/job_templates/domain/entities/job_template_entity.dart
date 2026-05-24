import 'template_service_item.dart';
import 'template_hardware_item.dart';
import 'template_part_item.dart';

class JobTemplateEntity {
  final String id;
  final String userId;
  final String name;
  final String serviceType;
  final String? notes;
  final List<TemplateServiceItem> services;
  final List<TemplateHardwareItem> hardwareItems;
  final List<TemplatePartItem> parts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobTemplateEntity({
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

  JobTemplateEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? serviceType,
    String? notes,
    List<TemplateServiceItem>? services,
    List<TemplateHardwareItem>? hardwareItems,
    List<TemplatePartItem>? parts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobTemplateEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      notes: notes ?? this.notes,
      services: services ?? this.services,
      hardwareItems: hardwareItems ?? this.hardwareItems,
      parts: parts ?? this.parts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
