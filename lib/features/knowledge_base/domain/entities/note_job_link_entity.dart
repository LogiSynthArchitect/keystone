import '../../../../core/constants/app_enums.dart';

class NoteJobLinkEntity {
  final String id;
  final String noteId;
  final String jobId;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  const NoteJobLinkEntity({
    required this.id,
    required this.noteId,
    required this.jobId,
    required this.createdAt,
    this.syncStatus = SyncStatus.synced,
  });

  NoteJobLinkEntity copyWith({
    String? id,
    String? noteId,
    String? jobId,
    DateTime? createdAt,
    SyncStatus? syncStatus,
  }) {
    return NoteJobLinkEntity(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      jobId: jobId ?? this.jobId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
