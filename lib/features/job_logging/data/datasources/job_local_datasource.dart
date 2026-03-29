import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_model.dart';

class JobLocalDatasource {
  Box<Map> get _box => HiveService.jobs;
  Box<Map> get _followUpBox => HiveService.followUps;

  Future<JobModel?> getJob(String id) async {
    try {
      final raw = _box.get(id);
      if (raw != null) {
        return JobModel.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    } catch (e) {
      throw StorageException(message: 'Could not read local job by ID.', code: 'LOCAL_READ_FAILED', cause: e);
    }
  }

  Future<void> saveJob(JobModel job) async {
    try {
      await _box.put(job.id, job.toJson().cast<String, dynamic>());
      await _box.flush(); // Force immediate disk persistence
    } catch (e) {
      throw StorageException(message: 'Could not save job locally.', code: 'LOCAL_SAVE_FAILED', cause: e);
    }
  }

  Future<List<JobModel>> getJobs({int limit = 500, int offset = 0}) async {
    try {
      // PERFORMANCE FIX: Use keys to selectively load models from memory
      final keys = _box.keys.toList().reversed.skip(offset).take(limit);
      final list = <JobModel>[];
      for (var key in keys) {
        final raw = _box.get(key);
        if (raw != null) {
          list.add(JobModel.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
      return list;
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
        await _box.flush();
      }
    } catch (e) {
      throw StorageException(message: 'Could not update sync status.', code: 'LOCAL_UPDATE_FAILED', cause: e);
    }
  }

  Future<void> deleteJob(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Future<void> cascadeCustomerId(String oldId, String newId) async {
    try {
      final keysToUpdate = [];
      for (var key in _box.keys) {
        final raw = _box.get(key);
        if (raw == null) continue;
        final jobMap = Map<String, dynamic>.from(raw);
        if (jobMap['customer_id'] == oldId) {
          keysToUpdate.add(key);
        }
      }

      for (var key in keysToUpdate) {
        final raw = _box.get(key);
        if (raw == null) continue;
        final jobMap = Map<String, dynamic>.from(raw);
        jobMap['customer_id'] = newId;
        await _box.put(key, jobMap);
      }
      if (keysToUpdate.isNotEmpty) await _box.flush();
    } catch (e) {
      throw StorageException(message: 'Could not cascade customer ID.', code: 'CASCADE_FAILED', cause: e);
    }
  }

  // Task 2: Redirect Cascade - Re-link WhatsApp Follow-ups specifically
  Future<void> cascadeJobId(String oldId, String newId) async {
    try {
      final followUpsToUpdate = [];
      for (var key in _followUpBox.keys) {
        final raw = _followUpBox.get(key);
        if (raw == null) continue;
        final followUpMap = Map<String, dynamic>.from(raw);
        if (followUpMap['job_id'] == oldId) {
          followUpsToUpdate.add(key);
        }
      }

      for (var key in followUpsToUpdate) {
        final raw = _followUpBox.get(key);
        if (raw == null) continue;
        final followUpMap = Map<String, dynamic>.from(raw);
        followUpMap['job_id'] = newId;
        await _followUpBox.put(key, followUpMap);
      }
      if (followUpsToUpdate.isNotEmpty) await _followUpBox.flush();
    } catch (e) {
      throw StorageException(message: 'Could not cascade job ID to child records.', code: 'CHILD_CASCADE_FAILED', cause: e);
    }
  }
}
