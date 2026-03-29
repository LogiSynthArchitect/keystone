import '../../domain/entities/note_job_link_entity.dart';

class NoteJobLinkModel {
  final String id;
  final String noteId;
  final String jobId;
  final String createdAt;

  const NoteJobLinkModel({
    required this.id,
    required this.noteId,
    required this.jobId,
    required this.createdAt,
  });

  factory NoteJobLinkModel.fromJson(Map<String, dynamic> json) => NoteJobLinkModel(
        id: json['id'] as String,
        noteId: json['note_id'] as String,
        jobId: json['job_id'] as String,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'note_id': noteId,
        'job_id': jobId,
        'created_at': createdAt,
      };

  NoteJobLinkEntity toEntity() => NoteJobLinkEntity(
        id: id,
        noteId: noteId,
        jobId: jobId,
        createdAt: DateTime.parse(createdAt),
      );
}
