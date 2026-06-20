import '../../domain/entities/job_photo_entity.dart';

class JobPhotoModel {
  final String id;
  final String jobId;
  final String storagePath;
  final String? label;
  final String mediaType;
  final String createdAt;

  const JobPhotoModel({
    required this.id,
    required this.jobId,
    required this.storagePath,
    this.label,
    this.mediaType = 'image',
    required this.createdAt,
  });

  factory JobPhotoModel.fromJson(Map<String, dynamic> json) => JobPhotoModel(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        storagePath: (json['storage_path'] as String?) ?? '',
        label: json['label'] as String?,
        mediaType: json['media_type'] as String? ?? 'image',
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'storage_path': storagePath,
        'label': label,
        'media_type': mediaType,
        'created_at': createdAt,
      };

  factory JobPhotoModel.fromEntity(JobPhotoEntity entity) => JobPhotoModel(
        id: entity.id,
        jobId: entity.jobId,
        storagePath: entity.storagePath,
        label: entity.label,
        mediaType: entity.mediaType,
        createdAt: entity.createdAt.toIso8601String(),
      );

  JobPhotoEntity toEntity() => JobPhotoEntity(
        id: id,
        jobId: jobId,
        storagePath: storagePath,
        label: label,
        mediaType: mediaType,
        createdAt: DateTime.parse(createdAt),
      );
}
