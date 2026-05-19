import '../../domain/entities/job_service_entity.dart';

class JobServiceModel {
  final String id;
  final String jobId;
  final String serviceType;
  final int quantity;
  final int? unitPrice;
  final String? domain;
  final String? notes;
  final int sortOrder;
  final String createdAt;

  const JobServiceModel({
    required this.id,
    required this.jobId,
    required this.serviceType,
    this.quantity = 1,
    this.unitPrice,
    this.domain,
    this.notes,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory JobServiceModel.fromJson(Map<String, dynamic> json) => JobServiceModel(
    id: json['id'],
    jobId: json['job_id'],
    serviceType: json['service_type'] as String? ?? '',
    quantity: json['quantity'] as int? ?? 1,
    unitPrice: json['unit_price'] as int?,
    domain: json['domain'] as String?,
    notes: json['notes'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
    createdAt: json['created_at'],
  );

  factory JobServiceModel.fromEntity(JobServiceEntity entity) => JobServiceModel(
    id: entity.id,
    jobId: entity.jobId,
    serviceType: entity.serviceType,
    quantity: entity.quantity,
    unitPrice: entity.unitPrice,
    domain: entity.domain,
    notes: entity.notes,
    sortOrder: entity.sortOrder,
    createdAt: entity.createdAt.toIso8601String(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'job_id': jobId,
    'service_type': serviceType,
    'quantity': quantity,
    'unit_price': unitPrice,
    'domain': domain,
    'notes': notes,
    'sort_order': sortOrder,
    'created_at': createdAt,
  };

  JobServiceEntity toEntity() => JobServiceEntity(
    id: id,
    jobId: jobId,
    serviceType: serviceType,
    quantity: quantity,
    unitPrice: unitPrice,
    domain: domain,
    notes: notes,
    sortOrder: sortOrder,
    createdAt: DateTime.parse(createdAt),
  );
}

