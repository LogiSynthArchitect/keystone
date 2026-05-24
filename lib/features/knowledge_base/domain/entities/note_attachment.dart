enum AttachmentType { image, audio, document }

class NoteAttachment {
  final String id;
  final AttachmentType type;
  final String url;
  final String name;
  final int? size;
  final String? mimeType;
  final int? duration;
  final DateTime createdAt;

  const NoteAttachment({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
    this.size,
    this.mimeType,
    this.duration,
    required this.createdAt,
  });

  NoteAttachment copyWith({
    String? id,
    AttachmentType? type,
    String? url,
    String? name,
    int? size,
    String? mimeType,
    int? duration,
    DateTime? createdAt,
  }) {
    return NoteAttachment(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      name: name ?? this.name,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
