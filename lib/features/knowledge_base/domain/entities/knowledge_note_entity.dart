class KnowledgeNoteEntity {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> tags;
  final String? photoUrl;
  final String? serviceType;
  final bool isArchived;
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
    this.serviceType,
    required this.isArchived,
    this.lastEditedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get hasTags  => tags.isNotEmpty;

  KnowledgeNoteEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? tags,
    String? photoUrl,
    String? serviceType,
    bool? isArchived,
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
      serviceType: serviceType ?? this.serviceType,
      isArchived: isArchived ?? this.isArchived,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
