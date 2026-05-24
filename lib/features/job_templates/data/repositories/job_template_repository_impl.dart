import 'package:flutter/foundation.dart';
import '../datasources/job_template_local_datasource.dart';
import '../datasources/job_template_remote_datasource.dart';
import '../models/job_template_model.dart';
import '../../domain/entities/job_template_entity.dart';
import '../../domain/repositories/job_template_repository.dart';

class JobTemplateRepositoryImpl implements JobTemplateRepository {
  final JobTemplateLocalDatasource _local;
  final JobTemplateRemoteDatasource? _remote;

  JobTemplateRepositoryImpl(this._local, [this._remote]);

  @override
  Future<List<JobTemplateEntity>> getTemplates(String userId) async {
    // Load from local first for speed
    final localModels = await _local.getAll();
    final templates = localModels.map((m) => m.toEntity()).toList();

    // Silently fetch from remote to stay fresh
    _syncFromRemote(userId);
    return templates;
  }

  @override
  Future<JobTemplateEntity> saveTemplate(JobTemplateEntity template) async {
    final model = JobTemplateModel.fromEntity(template);
    await _local.saveTemplate(model);

    // Fire-and-forget to remote
    _syncToRemote(model);
    return model.toEntity();
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _local.deleteTemplate(id);

    // Fire-and-forget to remote
    _deleteRemote(id);
  }

  @override
  Future<void> renameTemplate(String id, String newName) async {
    await _local.renameTemplate(id, newName);

    // Fire-and-forget to remote
    _renameRemote(id, newName);
  }

  // ── Remote sync helpers (fire-and-forget) ──

  Future<void> _syncFromRemote(String userId) async {
    if (_remote == null) return;
    try {
      final remoteModels = await _remote!.getTemplates(userId);
      for (final remote in remoteModels) {
        await _local.saveTemplate(remote);
      }
      // Clean up local templates not in remote (deleted on other devices)
      final localIds = (await _local.getAll()).map((m) => m.id).toSet();
      final remoteIds = remoteModels.map((m) => m.id).toSet();
      for (final localId in localIds.difference(remoteIds)) {
        await _local.deleteTemplate(localId);
      }
    } catch (e) {
      debugPrint('[KS:TEMPLATES] Remote sync failed: $e');
    }
  }

  Future<void> _syncToRemote(JobTemplateModel model) async {
    if (_remote == null) return;
    try {
      await _remote!.saveTemplate(model.toJson());
    } catch (e) {
      debugPrint('[KS:TEMPLATES] Remote save failed: $e');
    }
  }

  Future<void> _deleteRemote(String id) async {
    if (_remote == null) return;
    try {
      await _remote!.deleteTemplate(id);
    } catch (e) {
      debugPrint('[KS:TEMPLATES] Remote delete failed: $e');
    }
  }

  Future<void> _renameRemote(String id, String newName) async {
    if (_remote == null) return;
    try {
      await _remote!.saveTemplate({'id': id, 'name': newName, 'updated_at': DateTime.now().toIso8601String()});
    } catch (e) {
      debugPrint('[KS:TEMPLATES] Remote rename failed: $e');
    }
  }
}
