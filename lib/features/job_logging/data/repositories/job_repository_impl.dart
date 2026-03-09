import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/storage_exception.dart' as core_storage;
import '../../../../core/network/connectivity_service.dart';
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

  JobRepositoryImpl(this._remote, this._local, this._connectivity, this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<List<JobEntity>> getJobs({int limit = 25, int offset = 0}) async {
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final models = await _remote.getJobs(userId: _userId, limit: limit, offset: offset);
        for (final m in models) { await _local.saveJob(m); }
        return models.map((m) => m.toEntity()).toList();
      } catch (_) {}
    }
    final local = await _local.getJobs();
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

    // Step 1 — save locally first (must succeed)
    await _local.saveJob(model);

    // Step 2 — try remote sync
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final synced = await _remote.createJob({...json, 'sync_status': 'synced'});
        await _local.saveJob(synced);
        return synced.toEntity();
      } catch (_) {
        await _local.updateSyncStatus(job.id, 'pending');
      }
    }

    return model.toEntity();
  }

  @override
  Future<JobEntity> updateJob(JobEntity job) async {
    final json = _jobEntityToJson(job);
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      final updated = await _remote.updateJob(job.id, json);
      await _local.saveJob(updated);
      return updated.toEntity();
    }
    final model = JobModel.fromJson({...json, 'sync_status': 'pending'});
    await _local.saveJob(model);
    return model.toEntity();
  }

  @override
  Future<void> archiveJob(String id) async {
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      await _remote.updateJob(id, {'is_archived': true});
    }
    await _local.updateSyncStatus(id, 'pending');
  }

  @override
  Future<List<JobEntity>> getPendingSyncJobs() async {
    final pending = await _local.getPendingJobs();
    return pending.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> syncPendingJobs() async {
    final pending = await _local.getPendingJobs();
    if (pending.isEmpty) return;
    final isOnline = await _connectivity.isConnected;
    if (!isOnline) return;
    try {
      await _remote.batchSync(_userId, pending.map((m) => m.toJson()).toList());
      for (final job in pending) {
        await _local.updateSyncStatus(job.id, 'synced');
      }
    } catch (_) {}
  }

  Map<String, dynamic> _jobEntityToJson(JobEntity job) => {
    'id': job.id,
    'user_id': job.userId,
    'customer_id': job.customerId,
    'service_type': job.serviceType.name,
    'job_date': job.jobDate.toIso8601String().split('T').first,
    'location': job.location,
    'latitude': job.latitude,
    'longitude': job.longitude,
    'notes': job.notes,
    'amount_charged': job.amountCharged,
    'follow_up_sent': job.followUpSent,
    'follow_up_sent_at': job.followUpSentAt?.toIso8601String(),
    'sync_status': job.syncStatus.name,
    'is_archived': job.isArchived,
    'created_at': job.createdAt.toIso8601String(),
    'updated_at': job.updatedAt.toIso8601String(),
  };
}
