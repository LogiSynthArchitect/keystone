import 'package:flutter/foundation.dart';
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

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const core_storage.StorageException(message: 'Authentication session expired. Please log in again.', code: 'AUTH_MISSING');
    return id;
  }

  @override
  Future<List<JobEntity>> getJobs({int limit = 200, int offset = 0, bool includeArchived = false}) async {
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final remoteModels = await _remote.getJobs(userId: _userId, limit: limit, offset: offset);
        for (final m in remoteModels) { await _local.saveJob(m); }
      } catch (e) {
        debugPrint('[KS:JOBS] Remote fetch failed, serving from cache: $e');
      }
    }
    var local = await _local.getJobs(limit: limit, offset: offset);
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
        if (customer != null && customer.syncStatus != SyncStatus.pending) {
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
    
    if (existing.syncStatus == SyncStatus.synced) {
      if (DateTime.now().difference(existing.createdAt).inHours >= 24) {
        if (existing.serviceType != job.serviceType || existing.jobDate != job.jobDate) {
          throw const ValidationException(message: 'Service type and date are locked after 24 hours of syncing.', code: 'JOB_LOCKED');
        }
      }
    }
    final json = _jobEntityToJson(job);
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final updated = await _remote.updateJob(job.id, json);
        await _local.saveJob(updated);
        return updated.toEntity();
      } catch (e) {
        debugPrint('[KS:JOBS] Remote update failed, queuing as pending: $e');
      }
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
    } catch (e) {
      debugPrint('[KS:JOBS] archiveJob failed for id=$id: $e');
    }
  }

  @override
  Future<List<JobEntity>> getPendingSyncJobs() async {
    final pending = await _local.getPendingJobs();
    return pending.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> syncPendingJobs() async {
    debugPrint('[KS:SYNC] syncPendingJobs START');
    final pending = await _local.getPendingJobs();
    debugPrint('[KS:SYNC] Pending jobs: ${pending.length}');
    
    if (pending.isEmpty) return;
    
    final isOnline = await _connectivity.isConnected;
    debugPrint('[KS:SYNC] Connectivity: $isOnline');

    final safeToSync = <JobModel>[];
    for (final job in pending) {
      final customer = await _customerLocal.getCustomer(job.customerId);
      if (customer == null) {
        debugPrint('[KS:SYNC] Deleting orphaned job: ${job.id}');
        await _local.deleteJob(job.id);
      } else if (customer.syncStatus != SyncStatus.pending) {
        safeToSync.add(job);
      } else {
        debugPrint('[KS:SYNC] Job ${job.id} waiting for customer ${job.customerId} to sync');
      }
    }
    
    debugPrint('[KS:SYNC] Safe to sync: ${safeToSync.length}');
    if (safeToSync.isEmpty) return;

    try {
      final payload = safeToSync.map((m) => _jobEntityToJson(m.toEntity())).toList();
      debugPrint('[KS:SYNC] Sending ${payload.length} jobs for sync');
      
      final result = await _remote.batchSync(_userId, payload);
      debugPrint('[KS:SYNC] RPC Result: $result');

      final syncedList = result['synced'] as List<dynamic>? ?? [];
      final failedList = result['failed'] as List<dynamic>? ?? [];

      if (failedList.isNotEmpty) {
        for (var failure in failedList) {
          debugPrint('[KS:SYNC] FAILURE DETAIL: ${failure['local_id']} -> ${failure['error']}');
        }
      }

      // 1. Process successful syncs
      for (final syncedItem in syncedList) {
        final localId = syncedItem['local_id'] as String?;
        if (localId == null) continue;
        
        final serverId = syncedItem['server_id'] as String?;
        final originalJob = safeToSync.where((j) => j.id == localId).firstOrNull;
        if (originalJob == null || serverId == null) continue;

        final updatedJson = originalJob.toJson();
        updatedJson['id'] = serverId;
        updatedJson['sync_status'] = syncedItem['sync_status'] as String? ?? 'synced';
        
        await _local.saveJob(JobModel.fromJson(updatedJson));

        if (localId != serverId) {
          await _followUpRepo.updateJobId(localId, serverId);
          await _local.deleteJob(localId);
        }
      }

      // 2. Process failed syncs
      for (final failedItem in failedList) {
        final localId = failedItem['local_id'] as String?;
        if (localId == null) continue;

        final errorMessage = failedItem['error'] as String?;
        final originalJob = safeToSync.where((j) => j.id == localId).firstOrNull;
        
        if (originalJob != null) {
          final failedModel = originalJob.copyWith(
            syncStatus: SyncStatus.failed.name,
            syncErrorMessage: errorMessage ?? 'Server rejection',
          );
          await _local.saveJob(failedModel);
        }
      }
    } catch (e) {
      debugPrint('[KS:SYNC] FATAL ERROR (Network/Auth): $e');
      // DO NOT mark as failed here. 
      // Keeping them as 'pending' allows the next sync attempt (on refresh) to try again.
    }
  }

  Map<String, dynamic> _jobEntityToJson(JobEntity job) => {
    'id': job.id, 'user_id': job.userId, 'customer_id': job.customerId,
    'service_type': job.serviceType.name.replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}'), 
    'job_date': job.jobDate.toIso8601String().split('T').first,
    'location': job.location, 'latitude': job.latitude, 'longitude': job.longitude,
    'notes': job.notes, 'amount_charged': job.amountCharged != null ? job.amountCharged! / 100.0 : null,
    'follow_up_sent': job.followUpSent, 'follow_up_sent_at': job.followUpSentAt?.toIso8601String(),
    'sync_status': job.syncStatus.name, 'sync_error_message': job.syncErrorMessage,
    'is_archived': job.isArchived, 'created_at': job.createdAt.toIso8601String(),
    'updated_at': job.updatedAt.toIso8601String(),
  };
}
