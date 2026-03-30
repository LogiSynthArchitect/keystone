import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../../core/storage/hive_service.dart';

class FollowUpLocalDatasource {
  Box<Map> get _box => HiveService.followUps;

  Future<void> cascadeJobId(String oldId, String newId) async {
    try {
      final keysToUpdate = [];
      for (var key in _box.keys) {
        final map = Map<String, dynamic>.from(_box.get(key) ?? {});
        if (map['job_id'] == oldId) keysToUpdate.add(key);
      }
      for (var key in keysToUpdate) {
        final map = Map<String, dynamic>.from(_box.get(key) ?? {});
        map['job_id'] = newId;
        await _box.put(key, map);
      }
      if (keysToUpdate.isNotEmpty) await _box.flush();
    } catch (e) {
      throw StorageException(
        message: 'Could not cascade job ID in follow-ups.',
        code: 'FOLLOWUP_CASCADE_FAILED',
        cause: e,
      );
    }
  }

  Future<void> saveFollowUp(Map<String, dynamic> data) async {
    try {
      await _box.put(data['job_id'] as String, data);
      await _box.flush();
    } catch (e) {
      throw StorageException(
        message: 'Could not save follow-up locally.',
        code: 'FOLLOWUP_SAVE_FAILED',
        cause: e,
      );
    }
  }

  Future<Map<String, dynamic>?> getFollowUpByJobId(String jobId) async {
    final data = _box.get(jobId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> updateResponseStatus(String jobId, String status) async {
    try {
      final existing = _box.get(jobId);
      if (existing == null) return;
      final updated = Map<String, dynamic>.from(existing);
      updated['response_status'] = status;
      updated['response_updated_at'] = DateTime.now().toIso8601String();
      await _box.put(jobId, updated);
      await _box.flush();
    } catch (e) {
      throw StorageException(
        message: 'Could not update follow-up status.',
        code: 'FOLLOWUP_STATUS_UPDATE_FAILED',
        cause: e,
      );
    }
  }
}
