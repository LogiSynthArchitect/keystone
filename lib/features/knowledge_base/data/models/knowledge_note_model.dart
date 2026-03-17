import '../../domain/entities/knowledge_note_entity.dart';
import '../../../../core/constants/app_enums.dart';

class KnowledgeNoteModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> tags;
  final String? photoUrl;
  final String? serviceType;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  const KnowledgeNoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.tags,
    this.photoUrl,
    this.serviceType,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  factory KnowledgeNoteModel.fromJson(Map<String, dynamic> json) =>
      KnowledgeNoteModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        tags: List<String>.from(json['tags'] as List? ?? []),
        photoUrl: json['photo_url'] as String?,
        serviceType: json['service_type'] as String?,
        isArchived: json['is_archived'] as bool,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        syncStatus: json['sync_status'] as String? ?? 'synced',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'tags': tags,
        'photo_url': photoUrl,
        'service_type': serviceType,
        'is_archived': isArchived,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_status': syncStatus,
      };

  factory KnowledgeNoteModel.fromEntity(KnowledgeNoteEntity entity) =>
      KnowledgeNoteModel(
        id: entity.id,
        userId: entity.userId,
        title: entity.title,
        description: entity.description,
        tags: entity.tags,
        photoUrl: entity.photoUrl,
        serviceType: entity.serviceType?.name,
        isArchived: entity.isArchived,
        createdAt: entity.createdAt.toIso8601String(),
        updatedAt: entity.updatedAt.toIso8601String(),
        syncStatus: 'synced',
      );

  KnowledgeNoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? tags,
    String? photoUrl,
    String? serviceType,
    bool? isArchived,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) =>
      KnowledgeNoteModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        photoUrl: photoUrl ?? this.photoUrl,
        serviceType: serviceType ?? this.serviceType,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  KnowledgeNoteEntity toEntity() => KnowledgeNoteEntity(
        id: id,
        userId: userId,
        title: title,
        description: description,
        tags: tags,
        photoUrl: photoUrl,
        serviceType: serviceType != null ? _parseServiceType(serviceType!) : null,
        isArchived: isArchived,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  static ServiceType _parseServiceType(String value) {
    switch (value) {
      case 'car_lock_programming':    return ServiceType.carLockProgramming;
      case 'door_lock_installation':  return ServiceType.doorLockInstallation;
      case 'door_lock_repair':        return ServiceType.doorLockRepair;
      case 'smart_lock_installation': return ServiceType.smartLockInstallation;
      default:                        return ServiceType.doorLockRepair;
    }
  }
}
