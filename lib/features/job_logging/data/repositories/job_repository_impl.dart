import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/storage_exception.dart' as core_storage;
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/constants/app_enums.dart';
import 'package:keystone/features/customer_history/data/datasources/customer_local_datasource.dart';
import 'package:keystone/features/whatsapp_followup/domain/repositories/follow_up_repository.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/entities/job_part_entity.dart';
import '../../domain/entities/job_photo_entity.dart';
import '../../domain/entities/job_audit_entry_entity.dart';
import '../../domain/entities/job_service_entity.dart';
import '../../domain/entities/job_hardware_entity.dart';
import '../../domain/entities/job_expense_entity.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_remote_datasource.dart';
import '../datasources/job_local_datasource.dart';
import '../datasources/job_parts_local_datasource.dart';
import '../datasources/job_parts_remote_datasource.dart';
import '../datasources/job_photos_local_datasource.dart';
import '../datasources/job_photos_remote_datasource.dart';
import '../datasources/job_audit_local_datasource.dart';
import '../datasources/job_audit_remote_datasource.dart';
import '../datasources/job_services_local_datasource.dart';
import '../datasources/job_services_remote_datasource.dart';
import '../datasources/job_hardware_local_datasource.dart';
import '../datasources/job_hardware_remote_datasource.dart';
import '../datasources/job_expenses_local_datasource.dart';
import '../datasources/job_expenses_remote_datasource.dart';
import '../models/job_model.dart';
import '../models/job_part_model.dart';
import '../models/job_audit_entry_model.dart';
import '../models/job_service_model.dart';
import '../models/job_hardware_model.dart';
import '../models/job_expense_model.dart';

class JobRepositoryImpl implements JobRepository {
  final JobRemoteDatasource _remote;
  final JobLocalDatasource _local;
  final ConnectivityService _connectivity;
  final SupabaseClient _supabase;
  final CustomerLocalDatasource _customerLocal;
  final FollowUpRepository _followUpRepo;
  
  final JobPartsLocalDatasource _partsLocal;
  final JobPartsRemoteDatasource _partsRemote;
  final JobPhotosLocalDatasource _photosLocal;
  final JobAuditLocalDatasource _auditLocal;
  final JobAuditRemoteDatasource _auditRemote;
  final JobServicesLocalDatasource _servicesLocal;
  final JobServicesRemoteDatasource _servicesRemote;
  final JobHardwareLocalDatasource _hardwareLocal;
  final JobHardwareRemoteDatasource _hardwareRemote;
  final JobExpensesLocalDatasource _expensesLocal;
  final JobExpensesRemoteDatasource _expensesRemote;

  JobRepositoryImpl(
    this._remote,
    this._local,
    this._connectivity,
    this._supabase,
    this._customerLocal,
    this._followUpRepo,
    this._partsLocal,
    this._partsRemote,
    this._photosLocal,
    JobPhotosRemoteDatasource _photosRemote,
    this._auditLocal,
    this._auditRemote,
    this._servicesLocal,
    this._servicesRemote,
    this._hardwareLocal,
    this._hardwareRemote,
    this._expensesLocal,
    this._expensesRemote,
  );

  String? _cachedInternalUserId;
  String? _cachedAuthId;

  Future<String> _getInternalUserId() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) throw const core_storage.StorageException(message: 'Authentication session expired. Please log in again.', code: 'AUTH_MISSING');
    if (_cachedInternalUserId != null && _cachedAuthId != authId) {
      _cachedInternalUserId = null;
      _cachedAuthId = null;
    }
    if (_cachedInternalUserId != null) return _cachedInternalUserId!;
    final result = await _supabase.from('users').select('id').eq('auth_id', authId).single();
    _cachedInternalUserId = result['id'] as String;
    _cachedAuthId = authId;
    return _cachedInternalUserId!;
  }

  @override
  Future<List<JobEntity>> getJobs({int limit = 200, int offset = 0, bool includeArchived = false}) async {
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final remoteModels = await _remote.getJobs(userId: await _getInternalUserId(), limit: limit, offset: offset);
        for (final m in remoteModels) {
          final existing = await _local.getJob(m.id);
          if (existing != null && (existing.isArchived || existing.isDeleted) && existing.syncStatus == SyncStatus.pending.name) {
            continue;
          }
          await _local.saveJob(m);
        }
      } catch (e) {
        debugPrint('[KS:JOBS] Remote fetch failed, serving from cache: $e');
      }
    }
    var local = await _local.getJobs(limit: limit, offset: offset);
    if (!includeArchived) local = local.where((j) => !j.isArchived && !j.isDeleted).toList();
    local.sort((a, b) {
      final dateCompare = b.jobDate.compareTo(a.jobDate);
      return dateCompare != 0 ? dateCompare : b.createdAt.compareTo(a.createdAt);
    });
    return local.map((m) => m.toEntity()).toList();
  }

  @override
  Future<JobEntity?> getJobById(String id) async {
    final jobs = await _local.getJobs();
    final found = jobs.where((j) => j.id == id).firstOrNull;
    return found?.toEntity();
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
        debugPrint('[KS:JOBS] Remote create failed, job stays pending for retry: $e');
      }
    }
    return model.toEntity();
  }

  @override
  Future<JobEntity> updateJob(JobEntity job) async {
    final json = _jobEntityToJson(job);
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        // Conflict resolution: if the server has a newer version, it wins.
        final serverUpdatedAt = await _remote.fetchServerUpdatedAt(job.id);
        if (serverUpdatedAt != null && serverUpdatedAt.isAfter(job.updatedAt)) {
          debugPrint('[KS:JOBS] Conflict detected for ${job.id}: server is newer (${serverUpdatedAt.toIso8601String()} > ${job.updatedAt.toIso8601String()}). Using server version.');
          final serverJobs = await _remote.getJobs(userId: job.userId);
          final serverJob = serverJobs.where((j) => j.id == job.id).firstOrNull;
          if (serverJob != null) {
            // Log the conflict as an audit entry so the timeline shows it
            final conflictAudit = JobAuditEntryEntity(
              id: const Uuid().v4(),
              jobId: job.id,
              userId: job.userId,
              action: 'conflict_resolved',
              oldValues: {'conflict_local': _jobEntityToJson(job)},
              newValues: {'resolution': 'server_won', 'note': 'Server had newer data'},
              createdAt: DateTime.now(),
            );
            await _auditLocal.saveAll([JobAuditEntryModel(
              id: conflictAudit.id, jobId: conflictAudit.jobId,
              userId: conflictAudit.userId, action: conflictAudit.action,
              oldValues: conflictAudit.oldValues,
              newValues: conflictAudit.newValues,
              createdAt: conflictAudit.createdAt.toIso8601String(),
            )]);

            await _local.saveJob(serverJob);
            return serverJob.toEntity();
          }
        }
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
      if (job == null) return;

      if (job.syncStatus == SyncStatus.pending) {
        await _local.deleteJob(id);
        return;
      }

      final archivedModel = JobModel.fromEntity(job.copyWith(isArchived: true, syncStatus: SyncStatus.pending));
      await _local.saveJob(archivedModel);
      
      try {
        if (await _connectivity.isConnected) {
          await _remote.updateJob(id, {'is_archived': true});
          await _local.updateSyncStatus(id, 'synced');
        }
      } catch (e) {
        debugPrint('[KS:JOBS] archiveJob remote sync failed: $e');
      }
    } catch (e) {
      debugPrint('[KS:JOBS] archiveJob local operation failed: $e');
      rethrow;
    }
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
    
    if (!await _connectivity.isConnected) return;

    final safeToSync = <JobModel>[];
    for (final job in pending) {
      // Skip jobs whose customer hasn't synced yet — don't delete, retry next cycle
      if (job.customerId.isEmpty) continue;
      final customer = await _customerLocal.getCustomer(job.customerId);
      if (customer == null) continue;
      if (customer.syncStatus == SyncStatus.synced) {
        safeToSync.add(job);
      }
    }
    
    if (safeToSync.isEmpty) return;

    try {
      final payload = safeToSync.map((m) => _jobEntityToJson(m.toEntity())).toList();
      final result = await _remote.batchSync(await _getInternalUserId(), payload);

      final syncedList = result['synced'] as List<dynamic>? ?? [];
      final failedList = result['failed'] as List<dynamic>? ?? [];

      for (final syncedItem in syncedList) {
        final localId = syncedItem['local_id'] as String?;
        final serverId = syncedItem['server_id'] as String?;
        final originalJob = safeToSync.where((j) => j.id == localId).firstOrNull;
        if (originalJob == null || serverId == null || localId == null) continue;

        final updatedJson = originalJob.toJson();
        updatedJson['id'] = serverId;
        updatedJson['sync_status'] = 'synced';
        await _local.saveJob(JobModel.fromJson(updatedJson));

        if (localId != serverId) {
          await _followUpRepo.updateJobId(localId, serverId);
          await _syncChildEntities(localId, serverId);
          await _local.deleteJob(localId);
        } else {
          await _syncChildEntities(localId, serverId);
        }
      }

      for (final failedItem in failedList) {
        final localId = failedItem['local_id'] as String?;
        final errorMessage = failedItem['error'] as String?;
        final originalJob = safeToSync.where((j) => j.id == localId).firstOrNull;
        if (originalJob != null) {
          await _local.saveJob(originalJob.copyWith(syncStatus: SyncStatus.failed.name, syncErrorMessage: errorMessage));
        }
      }
    } catch (e) {
      debugPrint('[KS:SYNC] syncPendingJobs FATAL: $e');
    }
  }

  /// After a job is batch-synced, push its children to remote.
  /// Updates local child records to use the new server job_id,
  /// then upserts them to the server.
  Future<void> _syncChildEntities(String localJobId, String serverJobId) async {
    if (!await _connectivity.isConnected) return;

    try {
      // Services
      final services = await _servicesLocal.getServicesForJob(localJobId);
      if (services.isNotEmpty) {
        final updated = services.map((m) => JobServiceModel(
          id: m.id,
          jobId: serverJobId,
          serviceType: m.serviceType,
          quantity: m.quantity,
          unitPrice: m.unitPrice,
          domain: m.domain,
          notes: m.notes,
          sortOrder: m.sortOrder,
          createdAt: m.createdAt,
        )).toList();
        await _servicesRemote.upsertAll(updated.map((m) => m.toJson()).toList());
        await _servicesLocal.saveAll(updated);
      }

      // Hardware items
      final hardware = await _hardwareLocal.getHardwareForJob(localJobId);
      if (hardware.isNotEmpty) {
        final updated = hardware.map((m) => JobHardwareModel(
          id: m.id,
          jobId: serverJobId,
          domain: m.domain,
          category: m.category,
          brand: m.brand,
          model: m.model,
          keySpec: m.keySpec,
          material: m.material,
          finish: m.finish,
          dimensions: m.dimensions,
          quantity: m.quantity,
          unitSalePrice: m.unitSalePrice,
          unitCostPrice: m.unitCostPrice,
          notes: m.notes,
          sortOrder: m.sortOrder,
          createdAt: m.createdAt,
        )).toList();
        await _hardwareRemote.upsertAll(updated.map((m) => m.toJson()).toList());
        await _hardwareLocal.saveAll(updated);
      }

      // Parts
      final parts = await _partsLocal.getPartsForJob(localJobId);
      if (parts.isNotEmpty) {
        final updated = parts.map((m) => JobPartModel(
          id: m.id,
          jobId: serverJobId,
          partName: m.partName,
          quantity: m.quantity,
          unitPrice: m.unitPrice,
          inventoryItemId: m.inventoryItemId,
          createdAt: m.createdAt,
        )).toList();
        await _partsRemote.upsertAll(updated.map((m) => m.toJson()).toList());
        await _partsLocal.saveAll(updated);
      }

      // Expenses
      final expenses = await _expensesLocal.getExpensesForJob(localJobId);
      if (expenses.isNotEmpty) {
        final updated = expenses.map((m) => JobExpenseModel(
          id: m.id,
          jobId: serverJobId,
          category: m.category,
          description: m.description,
          amount: m.amount,
          createdAt: m.createdAt,
        )).toList();
        await _expensesRemote.upsertAll(updated.map((m) => m.toJson()).toList());
        await _expensesLocal.saveAll(updated);
      }

      debugPrint('[KS:SYNC] Synced children for job $localJobId → $serverJobId');
    } catch (e) {
      debugPrint('[KS:SYNC] Child entity sync failed for $localJobId: $e');
    }
  }

  // --- V2 Methods ---

  @override
  Future<List<JobPartEntity>> getPartsForJob(String jobId) async {
    final models = await _partsLocal.getPartsForJob(jobId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<JobPhotoEntity>> getPhotosForJob(String jobId) async {
    final models = await _photosLocal.getPhotosForJob(jobId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<JobAuditEntryEntity>> getAuditLogForJob(String jobId) async {
    final models = await _auditLocal.getEntriesForJob(jobId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<JobEntity> editJob(String jobId, Map<String, dynamic> changes, String editedBy) async {
    final existing = await getJobById(jobId);
    if (existing == null) throw Exception('Job not found.');

    if (changes.containsKey('payment_status')) {
      final error = JobEntity.validatePaymentTransition(existing.status, existing.paymentStatus, changes['payment_status'] as String);
      if (error != null) throw Exception(error);
    }

    final now = DateTime.now();
    final List<JobAuditEntryEntity> audits = [];

    changes.forEach((key, newValue) {
      final oldValue = _getFieldValue(existing, key);
      if (oldValue != newValue) {
        audits.add(JobAuditEntryEntity(
          id: const Uuid().v4(),
          jobId: jobId,
          userId: editedBy,
          action: 'updated',
          oldValues: {key: oldValue},
          newValues: {key: newValue},
          createdAt: now,
        ));
      }
    });

    if (audits.isEmpty) return existing;

    final updatedEntity = _applyChanges(existing, changes).copyWith(updatedAt: now, syncStatus: SyncStatus.pending);
    await _local.saveJob(JobModel.fromEntity(updatedEntity));
    await _auditLocal.saveAll(audits.map((e) => JobAuditEntryModel(
      id: e.id, jobId: e.jobId, userId: e.userId, action: e.action, 
      oldValues: e.oldValues, newValues: e.newValues, createdAt: e.createdAt.toIso8601String()
    )).toList());

    if (await _connectivity.isConnected) {
      try {
        final remoteJob = await _remote.updateJob(jobId, changes);
        await _local.saveJob(remoteJob);
        // Best effort audit push
        await _auditRemote.insertAll(audits.map((e) => {
          'id': e.id, 'job_id': e.jobId, 'user_id': e.userId, 'action': e.action,
          'old_values': e.oldValues, 'new_values': e.newValues, 'created_at': e.createdAt.toIso8601String()
        }).toList());
        return remoteJob.toEntity();
      } catch (e) {
        debugPrint('[KS:JOBS] Remote editJob failed: $e');
      }
    }

    return updatedEntity;
  }

  @override
  Future<JobEntity> updateJobStatus(String jobId, String newStatus, String editedBy) async {
    final existing = await getJobById(jobId);
    if (existing == null) throw Exception('Job not found.');
    final error = JobEntity.validateStatusTransition(existing.status, newStatus);
    if (error != null) throw Exception(error);

    final now = DateTime.now().toIso8601String();
    final timestampKey = _statusTimestampKey(newStatus);
    final changes = <String, dynamic>{'status': newStatus};
    if (timestampKey != null) changes[timestampKey] = now;

    return editJob(jobId, changes, editedBy);
  }

  String? _statusTimestampKey(String status) {
    switch (status) {
      case 'quoted':      return 'quoted_at';
      case 'in_progress': return 'in_progress_at';
      case 'completed':   return 'completed_at';
      case 'invoiced':    return 'invoiced_at';
      default:            return null;
    }
  }

  @override
  Future<JobEntity> updatePaymentStatus(String jobId, String newStatus, String? method, String editedBy) async {
    final existing = await getJobById(jobId);
    if (existing == null) throw Exception('Job not found.');
    final error = JobEntity.validatePaymentTransition(existing.status, existing.paymentStatus, newStatus);
    if (error != null) throw Exception(error);
    return editJob(jobId, {
      'payment_status': newStatus,
      if (method != null) 'payment_method': method,
    }, editedBy);
  }

  // --- Services ---

  @override
  Future<List<JobServiceEntity>> getServicesForJob(String jobId) async {
    final models = await _servicesLocal.getServicesForJob(jobId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveServices(String jobId, List<JobServiceEntity> services) async {
    await _servicesLocal.deleteServicesForJob(jobId);
    if (services.isNotEmpty) {
      final models = services.map((s) => JobServiceModel.fromEntity(s)).toList();
      await _servicesLocal.saveAll(models);
      if (await _connectivity.isConnected) {
        try {
          await _servicesRemote.upsertAll(models.map((m) => m.toJson()).toList());
        } catch (e) {
            debugPrint('[KS:REPO] Remote upsert failed: $e');
          }
      }
    }
  }

  // --- Hardware ---

  @override
  Future<List<JobHardwareEntity>> getHardwareForJob(String jobId) async {
    final models = await _hardwareLocal.getHardwareForJob(jobId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveHardwareItems(String jobId, List<JobHardwareEntity> items) async {
    await _hardwareLocal.deleteHardwareForJob(jobId);
    if (items.isNotEmpty) {
      final models = items.map((h) => JobHardwareModel.fromEntity(h)).toList();
      await _hardwareLocal.saveAll(models);
      if (await _connectivity.isConnected) {
        try {
          await _hardwareRemote.upsertAll(models.map((m) => m.toJson()).toList());
        } catch (e) {
            debugPrint('[KS:REPO] Remote upsert failed: $e');
          }
      }
    }
  }

  // --- Parts ---

  @override
  Future<void> saveParts(String jobId, List<JobPartEntity> parts) async {
    await _partsLocal.deletePartsForJob(jobId);
    if (parts.isNotEmpty) {
      final models = parts.map((p) => JobPartModel.fromEntity(p)).toList();
      await _partsLocal.saveAll(models);
      if (await _connectivity.isConnected) {
        try {
          await _partsRemote.upsertAll(models.map((m) => m.toJson()).toList());
        } catch (e) {
            debugPrint('[KS:REPO] Remote upsert failed: $e');
          }
      }
    }
  }

  // --- Expenses ---

  @override
  Future<List<JobExpenseEntity>> getExpensesForJob(String jobId) async {
    final models = await _expensesLocal.getExpensesForJob(jobId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveExpenses(String jobId, List<JobExpenseEntity> expenses) async {
    await _expensesLocal.deleteExpensesForJob(jobId);
    if (expenses.isNotEmpty) {
      final models = expenses.map((e) => JobExpenseModel.fromEntity(e)).toList();
      await _expensesLocal.saveAll(models);
      if (await _connectivity.isConnected) {
        try {
          await _expensesRemote.upsertAll(models.map((m) => m.toJson()).toList());
        } catch (e) {
            debugPrint('[KS:REPO] Remote upsert failed: $e');
          }
      }
    }
  }

  dynamic _getFieldValue(JobEntity job, String key) {
    switch (key) {
      case 'service_type': return job.serviceType;
      case 'status': return job.status;
      case 'payment_status': return job.paymentStatus;
      case 'payment_method': return job.paymentMethod;
      case 'amount_charged': return job.amountCharged != null ? job.amountCharged! / 100.0 : null;
      case 'location': return job.location;
      case 'notes': return job.notes;
      case 'hardware_brand': return job.hardwareBrand;
      case 'hardware_keyway': return job.hardwareKeyway;
      default: return null;
    }
  }

  JobEntity _applyChanges(JobEntity job, Map<String, dynamic> changes) {
    DateTime? parseTs(String key) {
      final v = changes[key];
      return v is String ? DateTime.parse(v) : null;
    }

    return job.copyWith(
      serviceType: changes['service_type'] as String?,
      status: changes['status'] as String?,
      paymentStatus: changes['payment_status'] as String?,
      paymentMethod: changes['payment_method'] as String?,
      amountCharged: changes['amount_charged'] != null ? ((changes['amount_charged'] as num) * 100).round() : null,
      location: changes['location'] as String?,
      notes: changes['notes'] as String?,
      hardwareBrand: changes['hardware_brand'] as String?,
      hardwareKeyway: changes['hardware_keyway'] as String?,
      quotedAt: parseTs('quoted_at'),
      inProgressAt: parseTs('in_progress_at'),
      completedAt: parseTs('completed_at'),
      invoicedAt: parseTs('invoiced_at'),
    );
  }

  Map<String, dynamic> _jobEntityToJson(JobEntity job) => {
    'id': job.id, 'user_id': job.userId, 'customer_id': job.customerId,
    'service_type': job.serviceType, 
    'job_date': job.jobDate.toIso8601String().split('T').first,
    'location': job.location, 'latitude': job.latitude, 'longitude': job.longitude,
    'notes': job.notes, 'amount_charged': job.amountCharged != null ? job.amountCharged! / 100.0 : null,
    'follow_up_sent': job.followUpSent, 'follow_up_sent_at': job.followUpSentAt?.toIso8601String(),
    'sync_status': job.syncStatus.name, 'sync_error_message': job.syncErrorMessage,
    'is_archived': job.isArchived, 'is_deleted': job.isDeleted,
    'status': job.status, 'payment_status': job.paymentStatus, 'payment_method': job.paymentMethod,
    'quoted_price': job.quotedPrice != null ? job.quotedPrice! / 100.0 : null,
    'hardware_brand': job.hardwareBrand, 'hardware_keyway': job.hardwareKeyway,
    'quoted_at': job.quotedAt?.toIso8601String(),
    'in_progress_at': job.inProgressAt?.toIso8601String(),
    'completed_at': job.completedAt?.toIso8601String(),
    'invoiced_at': job.invoicedAt?.toIso8601String(),
    'created_at': job.createdAt.toIso8601String(),
    'updated_at': job.updatedAt.toIso8601String(),
  };
}
