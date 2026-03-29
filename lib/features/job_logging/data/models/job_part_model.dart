import '../../domain/entities/job_part_entity.dart';

class JobPartModel {
  final String id;
  final String jobId;
  final String partName;
  final int? quantity;
  final int? unitPrice;
  final String createdAt;

  const JobPartModel({
    required this.id,
    required this.jobId,
    required this.partName,
    this.quantity,
    this.unitPrice,
    required this.createdAt,
  });

  factory JobPartModel.fromJson(Map<String, dynamic> json) => JobPartModel(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        partName: json['part_name'] as String,
        quantity: json['quantity'] as int?,
        unitPrice: json['unit_price'] != null ? (num.parse(json['unit_price'].toString()) * 100).round() : null,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'part_name': partName,
        'quantity': quantity,
        'unit_price': unitPrice != null ? unitPrice! / 100.0 : null,
        'created_at': createdAt,
      };

  JobPartEntity toEntity() => JobPartEntity(
        id: id,
        jobId: jobId,
        partName: partName,
        quantity: quantity,
        unitPrice: unitPrice,
        createdAt: DateTime.parse(createdAt),
      );
}
