import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../domain/entities/follow_up_entity.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../datasources/follow_up_remote_datasource.dart';
import '../datasources/follow_up_local_datasource.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/auth_exception.dart';

class FollowUpRepositoryImpl implements FollowUpRepository {
  final FollowUpRemoteDatasource _remote;
  final SupabaseClient _supabase;
  final FollowUpLocalDatasource _local;

  FollowUpRepositoryImpl(this._remote, this._supabase, this._local);

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException(message: 'Authentication session expired. Please log in again.', code: 'SESSION_EXPIRED');
    return id;
  }

  @override
  Future<FollowUpEntity> createFollowUp(FollowUpEntity followUp) async {
    // Separate payloads: remote does not receive is_synced (not in Supabase schema).
    final remotePayload = {
      'job_id': followUp.jobId,
      'user_id': _userId,
      'customer_id': followUp.customerId,
      'message_text': followUp.messageText,
      'sent_at': followUp.sentAt.toIso8601String(),
      'delivery_confirmed': false,
    };
    final localPayload = {...remotePayload, 'is_synced': false};

    // Save locally first — record is preserved even if remote write fails.
    await _local.saveFollowUp(localPayload);

    try {
      final model = await _remote.createFollowUp(remotePayload);
      // Update local record with confirmed server ID.
      await _local.saveFollowUp({...localPayload, 'id': model.id, 'is_synced': true});
      return model.toEntity();
    } catch (e) {
      // Remote failed — local record exists. Will sync later.
      debugPrint('[KS:FOLLOWUP] Remote save failed, kept locally: $e');
      return followUp; // return original entity (id = '' is acceptable offline)
    }
  }

  @override
  Future<FollowUpEntity?> getFollowUpByJobId(String jobId) async {
    // Check local first — catches follow-ups saved but not yet synced to server.
    final localData = await _local.getFollowUpByJobId(jobId);
    if (localData != null) {
      return FollowUpEntity(
        id: localData['id'] as String? ?? '',
        jobId: localData['job_id'] as String,
        userId: localData['user_id'] as String,
        customerId: localData['customer_id'] as String,
        messageText: localData['message_text'] as String,
        sentAt: DateTime.parse(localData['sent_at'] as String),
        deliveryConfirmed: localData['delivery_confirmed'] as bool? ?? false,
        createdAt: DateTime.parse(localData['sent_at'] as String),
      );
    }
    // Fall back to remote.
    try {
      final model = await _remote.getFollowUpByJobId(jobId);
      return model?.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<FollowUpEntity>> getFollowUps({int limit = 25, int offset = 0}) async {
    return [];
  }

  // Task 4: Relational Safety - Orchestrated Job ID Swap in Follow-Ups
  @override
  Future<void> updateJobId(String oldJobId, String newJobId) async {
    await _local.cascadeJobId(oldJobId, newJobId);
  }

  @override
  Future<void> updateResponseStatus(String jobId, String status) async {
    await _local.updateResponseStatus(jobId, status);
    try {
      await _remote.updateResponseStatus(jobId, status);
    } catch (e) {
      debugPrint('[KS:FOLLOWUP] Remote status update failed: $e');
    }
  }
}
