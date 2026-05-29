enum AttachmentType { image, audio, document }

class NoteAttachment {
  final String id;
  final AttachmentType type;
  final String url; // active URL — localPath if available, else remoteUrl
  final String name;
  final int? size;
  final String? mimeType;
  final int? duration;
  final DateTime createdAt;
  final String? remoteUrl; // canonical remote URL, synced via JSONB
  final String? localPath; // transient Hive-only field, never synced

  const NoteAttachment({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
    this.size,
    this.mimeType,
    this.duration,
    required this.createdAt,
    this.remoteUrl,
    this.localPath,
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
    String? remoteUrl,
    String? localPath,
    bool clearLocalPath = false,
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
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localPath: clearLocalPath ? null : (localPath ?? this.localPath),
    );
  }
}
