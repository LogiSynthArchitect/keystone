import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/follow_up_entity.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../datasources/follow_up_remote_datasource.dart';
import '../datasources/follow_up_local_datasource.dart';

class FollowUpRepositoryImpl implements FollowUpRepository {
  final FollowUpRemoteDatasource _remote;
  final SupabaseClient _supabase;
  final FollowUpLocalDatasource _local;

  FollowUpRepositoryImpl(this._remote, this._supabase, this._local);

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<FollowUpEntity> createFollowUp(FollowUpEntity followUp) async {
    final model = await _remote.createFollowUp({
      'job_id': followUp.jobId,
      'user_id': _userId,
      'customer_id': followUp.customerId,
      'message_text': followUp.messageText,
      'sent_at': followUp.sentAt.toIso8601String(),
      'delivery_confirmed': false,
    });
    return model.toEntity();
  }

  @override
  Future<FollowUpEntity?> getFollowUpByJobId(String jobId) async {
    final model = await _remote.getFollowUpByJobId(jobId);
    return model?.toEntity();
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
}
