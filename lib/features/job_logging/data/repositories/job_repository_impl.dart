import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/storage_exception.dart' as core_storage;
import '../../../../core/errors/validation_exception.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/constants/app_enums.dart';
import 'package:keystone/features/customer_history/data/datasources/customer_local_datasource.dart';
import 'package:keystone/features/whatsapp_followup/domain/repositories/follow_up_repository.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_remote_datasource.dart';
import '../datasources/job_local_datasource.dart';
import '../models/job_model.dart';

class JobRepositoryImpl implements JobRepository {
  final JobRemoteDatasource _remote;
  final JobLocalDatasource _local;
  final ConnectivityService _connectivity;
  final SupabaseClient _supabase;
  final CustomerLocalDatasource _customerLocal;
  final FollowUpRepository _followUpRepo;

  JobRepositoryImpl(this._remote, this._local, this._connectivity, this._supabase, this._customerLocal, this._followUpRepo);

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<List<JobEntity>> getJobs({int limit = 25, int offset = 0, bool includeArchived = false}) async {
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final remoteModels = await _remote.getJobs(userId: _userId, limit: limit, offset: offset);
        for (final m in remoteModels) { await _local.saveJob(m); }
      } catch (_) {}
    }
    var local = await _local.getJobs();
    if (!includeArchived) local = local.where((j) => !j.isArchived).toList();
    local.sort((a, b) {
      final dateCompare = b.jobDate.compareTo(a.jobDate);
      return dateCompare != 0 ? dateCompare : b.createdAt.compareTo(a.createdAt);
    });
    return local.map((m) => m.toEntity()).toList();
  }

  @override
  Future<JobEntity> getJobById(String id) async {
    final jobs = await _local.getJobs();
    final found = jobs.where((j) => j.id == id).firstOrNull;
    if (found != null) return found.toEntity();
    throw const core_storage.StorageException(message: 'Job not found.', code: 'JOB_NOT_FOUND');
  }

  @override
  Future<JobEntity> createJob(JobEntity job) async {
    final json = _jobEntityToJson(job);
    final model = JobModel.fromJson({...json, 'sync_status': 'pending'});
    await _local.saveJob(model);
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final customer = await _customerLocal.getCustomer(job.customerId);
        if (customer != null && customer.syncStatus != 'pending') {
          final synced = await _remote.createJob({...json, 'sync_status': 'synced'});
          await _local.saveJob(synced);
          return synced.toEntity();
        }
      } catch (e) {
        final errorModel = JobModel.fromJson({...json, 'sync_status': 'failed', 'sync_error_message': e.toString()});
        await _local.saveJob(errorModel);
      }
    }
    return model.toEntity();
  }

  @override
  Future<JobEntity> updateJob(JobEntity job) async {
    JobEntity existing;
    try {
      existing = await getJobById(job.id);
    } catch (_) {
      final all = await _local.getJobs();
      final matched = all.where((j) => j.createdAt == job.createdAt.toIso8601String() && j.customerId == job.customerId).firstOrNull;
      if (matched == null) throw const core_storage.StorageException(message: "Job record lost or synced during edit. Please refresh.", code: "CONCURRENCY_CONFLICT");
      existing = matched.toEntity();
    }
    
    if (DateTime.now().difference(existing.createdAt).inHours >= 24) {
      if (existing.serviceType != job.serviceType || existing.jobDate != job.jobDate) {
        throw const ValidationException(message: 'Service type and date are locked after 24 hours.', code: 'JOB_LOCKED');
      }
    }
    final json = _jobEntityToJson(job);
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final updated = await _remote.updateJob(job.id, json);
        await _local.saveJob(updated);
        return updated.toEntity();
      } catch (_) {}
    }
    final model = JobModel.fromJson({...json, 'sync_status': 'pending'});
    await _local.saveJob(model);
    return model.toEntity();
  }

  @override
  Future<void> archiveJob(String id) async {
    try {
      final job = await getJobById(id);

      if (job.syncStatus == SyncStatus.pending) {
        await _local.deleteJob(id);
        return;
      }

      final archivedModel = JobModel.fromJson({..._jobEntityToJson(job), 'is_archived': true, 'sync_status': 'pending'});
      await _local.saveJob(archivedModel);
      if (await _connectivity.isConnected) {
        await _remote.updateJob(id, {'is_archived': true});
        await _local.updateSyncStatus(id, 'synced');
      }
    } catch (_) {}
  }

  @override
  Future<List<JobEntity>> getPendingSyncJobs() async {
    final pending = await _local.getPendingJobs();
    return pending.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> syncPendingJobs() async {
    final pending = await _local.getPendingJobs();
    if (pending.isEmpty || !(await _connectivity.isConnected)) return;
    
    final safeToSync = <JobModel>[];
    for (final job in pending) {
      final customer = await _customerLocal.getCustomer(job.customerId);
      // FIX [JOB-004]: Unblock jobs where customer sync failed. 
      // Allows Job sync attempt (server RLS/constraints will handle integrity).
      if (customer != null && customer.syncStatus != 'pending') {
        safeToSync.add(job);
      }
    }
    if (safeToSync.isEmpty) return;

    final result = await _remote.batchSync(_userId, safeToSync.map((m) => m.toJson()).toList());
    final syncedList = result['synced'] as List<dynamic>? ?? [];

    for (final syncedItem in syncedList) {
      final localId = syncedItem['local_id'] as String;
      final serverId = syncedItem['server_id'] as String;
      final originalJob = safeToSync.firstWhere((j) => j.id == localId);
      final updatedJson = originalJob.toJson();
      updatedJson['id'] = serverId;
      updatedJson['sync_status'] = syncedItem['sync_status'] as String;
      
      // FIX [JOB-006]: Order of reconciliation. 
      // Update follow-up link BEFORE deleting the local job ID to prevent orphans.
      if (localId != serverId) {
        await _followUpRepo.updateJobId(localId, serverId);
        await _local.deleteJob(localId);
      }
      await _local.saveJob(JobModel.fromJson(updatedJson));
    }
  }

  Map<String, dynamic> _jobEntityToJson(JobEntity job) => {
    'id': job.id, 'user_id': job.userId, 'customer_id': job.customerId,
    'service_type': job.serviceType.name, 'job_date': job.jobDate.toIso8601String().split('T').first,
    'location': job.location, 'latitude': job.latitude, 'longitude': job.longitude,
    'notes': job.notes, 'amount_charged': job.amountCharged,
    'follow_up_sent': job.followUpSent, 'follow_up_sent_at': job.followUpSentAt?.toIso8601String(),
    'sync_status': job.syncStatus.name, 'sync_error_message': job.syncErrorMessage,
    'is_archived': job.isArchived, 'created_at': job.createdAt.toIso8601String(),
    'updated_at': job.updatedAt.toIso8601String(),
  };
}
