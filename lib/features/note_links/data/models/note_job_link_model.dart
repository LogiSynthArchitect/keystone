import 'package:keystone/features/knowledge_base/domain/entities/note_job_link_entity.dart';
import '../../../../core/constants/app_enums.dart';

class NoteJobLinkModel {
  final String id;
  final String noteId;
  final String jobId;
  final String? userId;
  final String createdAt;
  final SyncStatus syncStatus;

  const NoteJobLinkModel({
    required this.id,
    required this.noteId,
    required this.jobId,
    this.userId,
    required this.createdAt,
    this.syncStatus = SyncStatus.synced,
  });

  factory NoteJobLinkModel.fromJson(Map<String, dynamic> json) {
    return NoteJobLinkModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      jobId: json['job_id'] as String,
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] as String,
      syncStatus: json['sync_status'] != null
          ? SyncStatus.values.firstWhere(
              (e) => e.name == json['sync_status'],
              orElse: () => SyncStatus.synced,
            )
          : SyncStatus.synced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'note_id': noteId,
    'job_id': jobId,
    if (userId != null) 'user_id': userId,
    'created_at': createdAt,
  };

  NoteJobLinkEntity toEntity() => NoteJobLinkEntity(
    id: id,
    noteId: noteId,
    jobId: jobId,
    createdAt: DateTime.parse(createdAt),
    syncStatus: syncStatus,
  );

  factory NoteJobLinkModel.fromEntity(NoteJobLinkEntity entity, {String? userId}) {
    return NoteJobLinkModel(
      id: entity.id,
      noteId: entity.noteId,
      jobId: entity.jobId,
      userId: userId,
      createdAt: entity.createdAt.toIso8601String(),
      syncStatus: entity.syncStatus,
    );
  }

  NoteJobLinkModel copyWith({SyncStatus? syncStatus}) => NoteJobLinkModel(
    id: id,
    noteId: noteId,
    jobId: jobId,
    userId: userId,
    createdAt: createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
