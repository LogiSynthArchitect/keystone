import '../../../../core/constants/app_enums.dart';

class KnowledgeNoteEntity {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> tags;
  final String? photoUrl;
  final ServiceType? serviceType;
  final bool isArchived;
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
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get hasTags  => tags.isNotEmpty;
}
