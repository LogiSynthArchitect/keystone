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
}
