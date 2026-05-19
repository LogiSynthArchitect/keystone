class NoteJobLinkEntity {
  final String id;
  final String noteId;
  final String jobId;
  final DateTime createdAt;

  const NoteJobLinkEntity({
    required this.id,
    required this.noteId,
    required this.jobId,
    required this.createdAt,
  });

  NoteJobLinkEntity copyWith({
    String? id,
    String? noteId,
    String? jobId,
    DateTime? createdAt,
  }) {
    return NoteJobLinkEntity(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      jobId: jobId ?? this.jobId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
