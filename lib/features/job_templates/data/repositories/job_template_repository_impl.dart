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
    // Load active templates from local for speed (excludes soft-deleted)
    final localModels = await _local.getAllActive();
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
    // Soft-delete locally — hidden from UI but kept for sync reconciliation
    await _local.softDeleteTemplate(id);

    // Fire-and-forget tombstone to remote
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
        if (remote.isDeleted) {
          // Tombstone: hard-delete from local Hive
          await _local.hardDeleteTemplate(remote.id);
        } else {
          // Active template: save locally
          await _local.saveTemplate(remote);
        }
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
      await _remote!.renameTemplate(id, newName);
    } catch (e) {
      debugPrint('[KS:TEMPLATES] Remote rename failed: $e');
    }
  }
}
