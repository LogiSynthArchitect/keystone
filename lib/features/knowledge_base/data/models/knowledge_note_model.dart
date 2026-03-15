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
      };

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
