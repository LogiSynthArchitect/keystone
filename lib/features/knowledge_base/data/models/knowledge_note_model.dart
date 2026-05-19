import '../../domain/entities/knowledge_note_entity.dart';

class KnowledgeNoteModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> tags;
  final String? photoUrl;
  final String? coverImageUrl;
  final String? serviceType;
  final String mediaType;
  final bool isArchived;
  final bool isPinned;
  final String? lastEditedAt;
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
    this.coverImageUrl,
    this.serviceType,
    this.mediaType = 'image',
    required this.isArchived,
    this.isPinned = false,
    this.lastEditedAt,
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
        coverImageUrl: json['cover_image_url'] as String?,
        serviceType: json['service_type'] as String?,
        mediaType: json['media_type'] as String? ?? 'image',
        isArchived: json['is_archived'] as bool,
        isPinned: json['is_pinned'] as bool? ?? false,
        lastEditedAt: json['last_edited_at'] as String?,
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
        'cover_image_url': coverImageUrl,
        'service_type': serviceType,
        'media_type': mediaType,
        'is_archived': isArchived,
        'is_pinned': isPinned,
        'last_edited_at': lastEditedAt,
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
        coverImageUrl: entity.coverImageUrl,
        serviceType: entity.serviceType,
        mediaType: entity.mediaType,
        isArchived: entity.isArchived,
        isPinned: entity.isPinned,
        lastEditedAt: entity.lastEditedAt?.toIso8601String(),
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
    String? coverImageUrl,
    String? serviceType,
    String? mediaType,
    bool? isArchived,
    bool? isPinned,
    String? lastEditedAt,
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
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        serviceType: serviceType ?? this.serviceType,
        mediaType: mediaType ?? this.mediaType,
        isArchived: isArchived ?? this.isArchived,
        isPinned: isPinned ?? this.isPinned,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
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
        coverImageUrl: coverImageUrl,
        serviceType: serviceType,
        mediaType: mediaType,
        isArchived: isArchived,
        isPinned: isPinned,
        lastEditedAt: lastEditedAt != null ? DateTime.parse(lastEditedAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
