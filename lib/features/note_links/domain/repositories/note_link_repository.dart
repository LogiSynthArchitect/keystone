import 'package:keystone/features/knowledge_base/domain/entities/note_job_link_entity.dart';

abstract class NoteLinkRepository {
  Future<List<NoteJobLinkEntity>> getLinksForNote(String noteId);
  Future<List<NoteJobLinkEntity>> getLinksForJob(String jobId);
  Future<NoteJobLinkEntity> createLink(String noteId, String jobId, String userId);
  Future<void> deleteLink(String id);
}
