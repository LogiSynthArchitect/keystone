import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_model.dart';

class JobLocalDatasource {
  Box get _box => HiveService.jobs;
  Box get _followUpBox => HiveService.followUps;

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
      // Eviction-safe query: always include actionable jobs (needs follow-up
      // or unpaid), then pad with newest non-actionable jobs up to [limit].
      // This prevents follow-up green dots from silently vanishing on techs
      // with 500+ jobs.
      final actionable = <JobModel>[];
      final nonActionable = <JobModel>[];

      // Iterate newest-first for natural sort preservation
      for (var key in _box.keys.toList().reversed) {
        final raw = _box.get(key);
        if (raw == null) continue;
        final job = JobModel.fromJson(Map<String, dynamic>.from(raw));
        // Actionable = follow-up not yet sent, or payment not fully collected
        if (!job.followUpSent || job.paymentStatus != 'paid') {
          actionable.add(job);
        } else {
          nonActionable.add(job);
        }
      }

      // Actionable jobs are always included regardless of limit
      final result = actionable;
      final remaining = limit - result.length;
      if (remaining > 0 && offset < nonActionable.length) {
        result.addAll(nonActionable.skip(offset).take(remaining));
      }
      return result;
    } catch (e) {
      throw StorageException(message: 'Could not read local jobs.', code: 'LOCAL_READ_FAILED', cause: e);
    }
  }

  Future<List<JobModel>> getPendingJobs() async {
    final all = await getJobs();
    return all.where((j) =>
      j.syncStatus == 'pending' &&
      j.subEntitiesSaved == true
    ).toList();
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
        jobMap['sync_status'] = 'pending'; // Re-flag for re-sync with new FK
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
