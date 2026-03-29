import '../../../customer_history/domain/entities/key_code_entry_entity.dart';

class KeyCodeEntryModel {
  final String id;
  final String customerId;
  final String? jobId;
  final String keyCode;
  final String? keyType;
  final String? bitting; // stored encrypted
  final String? description;
  final String createdAt;
  final String? updatedAt;

  const KeyCodeEntryModel({
    required this.id,
    required this.customerId,
    this.jobId,
    required this.keyCode,
    this.keyType,
    this.bitting,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory KeyCodeEntryModel.fromJson(Map<String, dynamic> json) => KeyCodeEntryModel(
    id: json['id'] as String,
    customerId: json['customer_id'] as String,
    jobId: json['job_id'] as String?,
    keyCode: json['key_code'] as String,
    keyType: json['key_type'] as String?,
    bitting: json['bitting_data'] as String?,
    description: json['description'] as String?,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'job_id': jobId,
    'key_code': keyCode,
    'key_type': keyType,
    'bitting_data': bitting,
    'description': description,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  KeyCodeEntryEntity toEntity({String? decryptedBitting}) => KeyCodeEntryEntity(
    id: id,
    customerId: customerId,
    jobId: jobId,
    keyCode: keyCode,
    keyType: keyType,
    bitting: decryptedBitting ?? bitting,
    description: description,
    createdAt: DateTime.parse(createdAt),
    updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
  );

  factory KeyCodeEntryModel.fromEntity(KeyCodeEntryEntity entity, {String? encryptedBitting}) =>
      KeyCodeEntryModel(
        id: entity.id,
        customerId: entity.customerId,
        jobId: entity.jobId,
        keyCode: entity.keyCode,
        keyType: entity.keyType,
        bitting: encryptedBitting ?? entity.bitting,
        description: entity.description,
        createdAt: entity.createdAt.toIso8601String(),
        updatedAt: entity.updatedAt?.toIso8601String(),
      );
}
