import 'package:keystone/core/storage/hive_service.dart';
import '../models/note_job_link_model.dart';

class NoteLinkLocalDatasource {
  List<NoteJobLinkModel> _all() {
    return HiveService.noteJobLinks.values
        .map((e) => NoteJobLinkModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<NoteJobLinkModel>> getForNote(String noteId) async {
    return _all().where((m) => m.noteId == noteId).toList();
  }

  Future<List<NoteJobLinkModel>> getForJob(String jobId) async {
    return _all().where((m) => m.jobId == jobId).toList();
  }

  Future<void> save(NoteJobLinkModel model) async {
    await HiveService.noteJobLinks.put(model.id, model.toJson());
    await HiveService.noteJobLinks.flush();
  }

  Future<void> delete(String id) async {
    await HiveService.noteJobLinks.delete(id);
    await HiveService.noteJobLinks.flush();
  }
}
