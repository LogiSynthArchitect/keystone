import '../../domain/entities/note_attachment.dart';

class NoteAttachmentModel {
  final String id;
  final String type; // 'image', 'audio', 'document'
  final String url;
  final String name;
  final int? size;
  final String? mimeType;
  final int? duration;
  final String createdAt;

  const NoteAttachmentModel({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
    this.size,
    this.mimeType,
    this.duration,
    required this.createdAt,
  });

  factory NoteAttachmentModel.fromEntity(NoteAttachment entity) =>
      NoteAttachmentModel(
        id: entity.id,
        type: entity.type.name,
        url: entity.url,
        name: entity.name,
        size: entity.size,
        mimeType: entity.mimeType,
        duration: entity.duration,
        createdAt: entity.createdAt.toIso8601String(),
      );

  factory NoteAttachmentModel.fromJson(Map<String, dynamic> json) =>
      NoteAttachmentModel(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'image',
        url: json['url'] as String,
        name: json['name'] as String? ?? '',
        size: json['size'] as int?,
        mimeType: json['mime_type'] as String?,
        duration: json['duration'] as int?,
        createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'url': url,
        'name': name,
        'size': size,
        'mime_type': mimeType,
        'duration': duration,
        'created_at': createdAt,
      };

  NoteAttachment toEntity() {
    AttachmentType parsedType;
    switch (type) {
      case 'audio':
        parsedType = AttachmentType.audio;
        break;
      case 'document':
        parsedType = AttachmentType.document;
        break;
      default:
        parsedType = AttachmentType.image;
    }
    return NoteAttachment(
      id: id,
      type: parsedType,
      url: url,
      name: name,
      size: size,
      mimeType: mimeType,
      duration: duration,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
