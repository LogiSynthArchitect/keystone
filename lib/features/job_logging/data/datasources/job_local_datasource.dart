import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_model.dart';

class JobLocalDatasource {
  Box<Map> get _box => HiveService.jobs;

  Future<void> saveJob(JobModel job) async {
    try {
      await _box.put(job.id, job.toJson().cast<String, dynamic>());
    } catch (e) {
      throw StorageException(message: 'Could not save job locally.', code: 'LOCAL_SAVE_FAILED', cause: e);
    }
  }

  Future<List<JobModel>> getJobs() async {
    try {
      return _box.values
          .map((e) => JobModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw StorageException(message: 'Could not read local jobs.', code: 'LOCAL_READ_FAILED', cause: e);
    }
  }

  Future<List<JobModel>> getPendingJobs() async {
    final all = await getJobs();
    return all.where((j) => j.syncStatus == 'pending').toList();
  }

  Future<void> updateSyncStatus(String id, String status) async {
    try {
      final existing = _box.get(id);
      if (existing != null) {
        final updated = Map<String, dynamic>.from(existing);
        updated['sync_status'] = status;
        await _box.put(id, updated);
      }
    } catch (e) {
      throw StorageException(message: 'Could not update sync status.', code: 'LOCAL_UPDATE_FAILED', cause: e);
    }
  }

  Future<void> deleteJob(String id) async {
    await _box.delete(id);
  }
}
