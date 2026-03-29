class JobPhotoEntity {
  final String id;
  final String jobId;
  final String storagePath;
  final String? label; // 'before', 'after', 'during', etc.
  final DateTime createdAt;

  const JobPhotoEntity({
    required this.id,
    required this.jobId,
    required this.storagePath,
    this.label,
    required this.createdAt,
  });
}
