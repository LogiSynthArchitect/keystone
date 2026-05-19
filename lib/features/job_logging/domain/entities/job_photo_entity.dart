class JobPhotoEntity {
  final String id;
  final String jobId;
  final String storagePath;
  final String? label;
  final String mediaType;
  final DateTime createdAt;

  const JobPhotoEntity({
    required this.id,
    required this.jobId,
    required this.storagePath,
    this.label,
    this.mediaType = 'image',
    required this.createdAt,
  });

  bool get isVideo => mediaType == 'video';
  bool get isAudio => mediaType == 'audio';
  bool get isImage => mediaType == 'image';

  JobPhotoEntity copyWith({
    String? id,
    String? jobId,
    String? storagePath,
    String? label,
    String? mediaType,
    DateTime? createdAt,
  }) {
    return JobPhotoEntity(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      storagePath: storagePath ?? this.storagePath,
      label: label ?? this.label,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
