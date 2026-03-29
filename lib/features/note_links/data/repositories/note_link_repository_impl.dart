import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:keystone/core/network/connectivity_service.dart';
import 'package:keystone/features/knowledge_base/domain/entities/note_job_link_entity.dart';
import '../datasources/note_link_local_datasource.dart';
import '../datasources/note_link_remote_datasource.dart';
import '../models/note_job_link_model.dart';
import '../../domain/repositories/note_link_repository.dart';

class NoteLinkRepositoryImpl implements NoteLinkRepository {
  final NoteLinkLocalDatasource _local;
  final NoteLinkRemoteDatasource _remote;
  final ConnectivityService _connectivity;

  NoteLinkRepositoryImpl(this._local, this._remote, this._connectivity);

  @override
  Future<List<NoteJobLinkEntity>> getLinksForNote(String noteId) async {
    if (await _connectivity.isConnected) {
      try {
        final remote = await _remote.getForNote(noteId);
        for (final m in remote) {
          await _local.save(m);
        }
      } catch (e) {
        debugPrint('[KS:NOTELINKS] Remote getForNote failed, using local: $e');
      }
    }
    final local = await _local.getForNote(noteId);
    return local.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<NoteJobLinkEntity>> getLinksForJob(String jobId) async {
    if (await _connectivity.isConnected) {
      try {
        final remote = await _remote.getForJob(jobId);
        for (final m in remote) {
          await _local.save(m);
        }
      } catch (e) {
        debugPrint('[KS:NOTELINKS] Remote getForJob failed, using local: $e');
      }
    }
    final local = await _local.getForJob(jobId);
    return local.map((m) => m.toEntity()).toList();
  }

  @override
  Future<NoteJobLinkEntity> createLink(String noteId, String jobId, String userId) async {
    final localModel = NoteJobLinkModel(
      id: const Uuid().v4(),
      noteId: noteId,
      jobId: jobId,
      userId: userId,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _local.save(localModel);

    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.create(localModel.toJson());
        await _local.save(remoteModel);
        return remoteModel.toEntity();
      } catch (e) {
        debugPrint('[KS:NOTELINKS] Remote createLink failed, using local: $e');
      }
    }
    return localModel.toEntity();
  }

  @override
  Future<void> deleteLink(String id) async {
    await _local.delete(id);
    if (await _connectivity.isConnected) {
      try {
        await _remote.delete(id);
      } catch (e) {
        debugPrint('[KS:NOTELINKS] Remote deleteLink failed, local deleted: $e');
      }
    }
  }
}
