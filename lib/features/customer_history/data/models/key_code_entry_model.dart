import '../../domain/entities/key_code_entry_entity.dart';

class KeyCodeEntryModel {
  final String id;
  final String customerId;
  final String? jobId;
  final String keyCode;
  final String? keyType;
  final String? bitting;
  final String? description;
  final String createdAt;

  const KeyCodeEntryModel({
    required this.id,
    required this.customerId,
    this.jobId,
    required this.keyCode,
    this.keyType,
    this.bitting,
    this.description,
    required this.createdAt,
  });

  factory KeyCodeEntryModel.fromJson(Map<String, dynamic> json) => KeyCodeEntryModel(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        jobId: json['job_id'] as String?,
        keyCode: json['key_code'] as String,
        keyType: json['key_type'] as String?,
        bitting: json['bitting'] as String?,
        description: json['description'] as String?,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'job_id': jobId,
        'key_code': keyCode,
        'key_type': keyType,
        'bitting': bitting,
        'description': description,
        'created_at': createdAt,
      };

  KeyCodeEntryEntity toEntity() => KeyCodeEntryEntity(
        id: id,
        customerId: customerId,
        jobId: jobId,
        keyCode: keyCode,
        keyType: keyType,
        bitting: bitting,
        description: description,
        createdAt: DateTime.parse(createdAt),
      );
}
