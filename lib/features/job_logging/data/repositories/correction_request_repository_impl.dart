import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/correction_request_entity.dart';
import '../../domain/repositories/correction_request_repository.dart';
import '../models/correction_request_model.dart';

class CorrectionRequestRepositoryImpl implements CorrectionRequestRepository {
  final SupabaseClient _supabase;

  CorrectionRequestRepositoryImpl(this._supabase);

  @override
  Future<CorrectionRequestEntity> createRequest(CorrectionRequestEntity request) async {
    final model = await _supabase.from('correction_requests').insert({
      'job_id': request.jobId,
      'user_id': request.userId,
      'reason': request.reason,
      'status': 'pending',
    }).select().single();
    
    return CorrectionRequestModel.fromJson(model).toEntity();
  }

  @override
  Future<List<CorrectionRequestEntity>> getMyRequests() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Authentication session expired.');
    final data = await _supabase
        .from('correction_requests')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
        
    return (data as List).map((json) => CorrectionRequestModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<List<CorrectionRequestEntity>> getAllPendingRequests() async {
    final data = await _supabase
        .from('correction_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
        
    return (data as List).map((json) => CorrectionRequestModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<void> approveRequest(String requestId, String jobId, Map<String, dynamic> updates) async {
    // 1. Update the job
    await _supabase.from('jobs').update(updates).eq('id', jobId);
    
    // 2. Mark request as approved
    await _supabase.from('correction_requests').update({
      'status': 'approved',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  @override
  Future<void> rejectRequest(String requestId, {String? adminNotes}) async {
    await _supabase.from('correction_requests').update({
      'status': 'rejected',
      'admin_notes': adminNotes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }
}
