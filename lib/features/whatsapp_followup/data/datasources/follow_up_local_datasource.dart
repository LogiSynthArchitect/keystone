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
}
