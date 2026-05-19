class KnowledgeNoteEntity {
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
  final DateTime? lastEditedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KnowledgeNoteEntity({
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
  });

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get hasTags  => tags.isNotEmpty;
  bool get isVideo => mediaType == 'video';
  bool get isAudio => mediaType == 'audio';
  bool get hasCover => coverImageUrl != null && coverImageUrl!.isNotEmpty;
  String? get displayImage => coverImageUrl ?? photoUrl;

  KnowledgeNoteEntity copyWith({
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
    DateTime? lastEditedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeNoteEntity(
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
    );
  }
}
