import '../../domain/entities/job_photo_entity.dart';

class JobPhotoModel {
  final String id;
  final String jobId;
  final String storagePath;
  final String? label;
  final String createdAt;

  const JobPhotoModel({
    required this.id,
    required this.jobId,
    required this.storagePath,
    this.label,
    required this.createdAt,
  });

  factory JobPhotoModel.fromJson(Map<String, dynamic> json) => JobPhotoModel(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        storagePath: json['storage_path'] as String,
        label: json['label'] as String?,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'storage_path': storagePath,
        'label': label,
        'created_at': createdAt,
      };

  JobPhotoEntity toEntity() => JobPhotoEntity(
        id: id,
        jobId: jobId,
        storagePath: storagePath,
        label: label,
        createdAt: DateTime.parse(createdAt),
      );
}
