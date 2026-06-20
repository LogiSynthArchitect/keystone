import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/storage_exception.dart' as core_storage;
import '../../../../core/errors/duplicate_customer_exception.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/services/sync/sync_queue_service.dart';
import 'package:arclock/features/job_logging/data/datasources/job_local_datasource.dart';
import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';
import '../datasources/customer_local_datasource.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDatasource _remote;
  final CustomerLocalDatasource _local;
  final ConnectivityService _connectivity;
  final SupabaseClient _supabase;
  final JobLocalDatasource _jobLocal;
  final SyncQueueService _syncQueue;

  CustomerRepositoryImpl(this._remote, this._local, this._connectivity, this._supabase, this._jobLocal, this._syncQueue);

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const core_storage.StorageException(message: 'Authentication session expired. Please log in again.', code: 'AUTH_MISSING');
    return id;
  }

  @override
  Future<List<CustomerEntity>> getCustomers() async {
    // Serve exclusively from local cache — the sync daemon handles
    // incremental delta pulls via pullRemoteChanges().
    final localModels = await _local.getCustomers();
    return localModels.map((m) => m.toEntity()).toList();
  }

  /// Pull incremental changes from the server using delta sync.
  /// On first launch (no prior sync), fetches ALL non-deleted customers.
  /// On subsequent calls, fetches only records with updated_at > last_synced_at
  /// minus a 5-second overlap window to prevent commit-timing race conditions.
  /// Handles soft-deletes: records with deleted_at > last_synced are hard-deleted
  /// from the local cache.
  ///
  /// The sync token is always the server's max updated_at from the response,
  /// NOT client DateTime.now() — this immunizes against device clock skew.
  ///
  /// Returns the number of changed records processed (0 if offline or no changes).
  @override
  Future<int> pullRemoteChanges() async {
    if (!await _connectivity.isConnected) return 0;
    try {
      var updatedAfter = _local.getLastSyncTimestamp();

      // Seed timestamp for existing users upgrading from pre-delta-sync version.
      // Without this, a null timestamp triggers a full re-download of all
      // customers on first background sync — wasteful for accounts with 500+
      // records. If there's already local data, assume it's up-to-date and
      // only pull changes from 24 hours ago onward.
      if (updatedAfter == null && (await _local.getCustomers()).isNotEmpty) {
        updatedAfter = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
        await _local.setLastSyncTimestamp(updatedAfter);
      }

      // Add 5-second overlap to the query window to catch records
      // committed at the exact boundary (PostgreSQL transaction timing).
      // The stored sync token is still the server's actual max updated_at.
      if (updatedAfter != null) {
        final overlapped = DateTime.parse(updatedAfter).subtract(const Duration(seconds: 5));
        updatedAfter = overlapped.toIso8601String();
      }

      final models = await _remote.getCustomers(userId: _userId, updatedAfter: updatedAfter);
      if (models.isEmpty) {
        // No changes since last sync — don't update the timestamp.
        // This keeps the existing sync window so the next pull retries
        // with the same boundary (safe with 5s overlap below).
        return 0;
      }

      for (final model in models) {
        if (model.deletedAt != null) {
          // Server-side soft-delete: remove from local cache
          await _local.deleteCustomer(model.id);
        } else {
          // Upsert: server state is authoritative for pulled records
          await _local.saveCustomer(model.copyWith(syncStatus: SyncStatus.synced));
        }
      }

      // Use the server's max updated_at as the sync token — NOT client time.
      // This immunizes delta sync against clock skew on the technician's phone.
      final serverTimestamp = models
          .map((m) => m.updatedAt)
          .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      await _local.setLastSyncTimestamp(serverTimestamp);
      return models.length;
    } catch (e) {
      debugPrint('[KS:SYNC:CUSTOMERS] Delta pull failed: $e');
      return 0;
    }
  }

  @override
  Future<CustomerEntity> getCustomerById(String id) async {
    if (await _connectivity.isConnected) {
      try {
        final model = await _remote.getCustomerById(id);
        if (model == null) throw const core_storage.StorageException(message: 'Customer not found remotely.', code: 'CUSTOMER_NOT_FOUND');
        await _local.saveCustomer(model);
        return model.toEntity();
      } catch (e) {
        debugPrint('[KS:CUSTOMERS] Remote getById failed, falling back to local: $e');
      }
    }
    var local = await _local.getCustomer(id);
    if (local != null) return local.toEntity();
    throw const core_storage.StorageException(message: 'Customer not found.', code: 'CUSTOMER_NOT_FOUND');
  }

  @override
  Future<CustomerEntity?> getCustomerByPhone(String phoneNumber) async {
    if (await _connectivity.isConnected) {
      try {
        final results = await _remote.searchCustomers(userId: _userId, query: phoneNumber);
        final match = results.where((m) => m.phoneNumber == phoneNumber).firstOrNull;
        if (match != null) await _local.saveCustomer(match);
        return match?.toEntity();
      } catch (e) {
        debugPrint('[KS:CUSTOMERS] Remote phone search failed, searching local: $e');
      }
    }
    final localModels = await _local.getCustomers();
    final match = localModels.where((m) => m.phoneNumber == phoneNumber).firstOrNull;
    return match?.toEntity();
  }

  @override
  Future<CustomerEntity> createCustomer(CustomerEntity customer) async {
    // Duplicate detection: check local cache first for same phone + same user
    final existing = await _local.getCustomers();
    final duplicate = existing.where((c) =>
      c.phoneNumber == customer.phoneNumber &&
      c.userId == _userId &&
      c.syncStatus != SyncStatus.deleted
    ).firstOrNull;
    if (duplicate != null) {
      throw DuplicateCustomerException(
        message: 'A customer with this phone number already exists.',
        existingCustomerId: duplicate.id,
        existingCustomerName: duplicate.fullName,
      );
    }

    final now = DateTime.now().toIso8601String();
    final localModel = CustomerModel(
      id: const Uuid().v4(),
      userId: _userId,
      fullName: customer.fullName,
      phoneNumber: customer.phoneNumber,
      location: customer.location,
      notes: customer.notes,
      totalJobs: 0,
      syncStatus: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await _local.saveCustomer(localModel);

    // Enqueue mutation for background sync worker
    final taskId = await _syncQueue.enqueue(
      tableName: 'customers',
      operation: 'INSERT',
      payload: localModel.toJson(),
      recordId: localModel.id,
    );

    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.createCustomer({
          'user_id': _userId,
          'full_name': customer.fullName,
          'phone_number': customer.phoneNumber,
          'location': customer.location,
          'notes': customer.notes,
        });
        
        final syncedModel = CustomerModel(
          id: remoteModel.id,
          userId: remoteModel.userId,
          fullName: remoteModel.fullName,
          phoneNumber: remoteModel.phoneNumber,
          location: remoteModel.location,
          notes: remoteModel.notes,
          totalJobs: remoteModel.totalJobs,
          lastJobAt: remoteModel.lastJobAt,
          syncStatus: SyncStatus.synced,
          createdAt: remoteModel.createdAt,
          updatedAt: remoteModel.updatedAt,
        );

        if (localModel.id != syncedModel.id) {
          await _jobLocal.cascadeCustomerId(localModel.id, syncedModel.id);
          await _local.deleteCustomer(localModel.id);
        }

        await _local.saveCustomer(syncedModel);
        await _syncQueue.markComplete(taskId);
        return syncedModel.toEntity();
      } catch (e) {
        debugPrint('[KS:CUSTOMERS] Remote create failed, customer queued as pending: $e');
        // Queue task remains for SyncWorker retry
      }
    }
    return localModel.toEntity();
  }

  @override
  Future<CustomerEntity> updateCustomer(CustomerEntity customer) async {
    final existing = await _local.getCustomer(customer.id);
    
    final pendingModel = CustomerModel(
      id: customer.id,
      userId: _userId,
      fullName: customer.fullName,
      phoneNumber: customer.phoneNumber,
      location: customer.location,
      notes: customer.notes,
      totalJobs: existing?.totalJobs ?? 0,
      lastJobAt: existing?.lastJobAt,
      syncStatus: SyncStatus.pending,
      propertyType: customer.propertyType,
      leadSource: customer.leadSource,
      createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    await _local.saveCustomer(pendingModel);

    final taskId = await _syncQueue.enqueue(
      tableName: 'customers',
      operation: 'UPDATE',
      payload: pendingModel.toJson(),
      recordId: customer.id,
    );

    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.updateCustomer(customer.id, {
          'full_name': customer.fullName,
          'phone_number': customer.phoneNumber,
          'location': customer.location,
          'notes': customer.notes,
          'property_type': customer.propertyType,
          'lead_source': customer.leadSource,
        });
        
        final syncedModel = CustomerModel(
          id: remoteModel.id,
          userId: remoteModel.userId,
          fullName: remoteModel.fullName,
          phoneNumber: remoteModel.phoneNumber,
          location: remoteModel.location,
          notes: remoteModel.notes,
          totalJobs: remoteModel.totalJobs,
          lastJobAt: remoteModel.lastJobAt,
          syncStatus: SyncStatus.synced,
          createdAt: remoteModel.createdAt,
          updatedAt: remoteModel.updatedAt,
        );
        await _local.saveCustomer(syncedModel);
        await _syncQueue.markComplete(taskId);
        return syncedModel.toEntity();
      } catch (e) {
        debugPrint('[KS:CUSTOMERS] Remote update failed, customer queued as pending: $e');
      }
    }
    return pendingModel.toEntity();
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      final existing = await _local.getCustomer(id);
      if (existing == null) return;

      // Mark as deleted locally (tombstone)
      await _local.tombstoneCustomer(id);

      final taskId = await _syncQueue.enqueue(
        tableName: 'customers',
        operation: 'DELETE',
        payload: {'id': id},
        recordId: id,
      );

      // Attempt remote delete if connected
      if (await _connectivity.isConnected) {
        try {
          await _remote.deleteCustomer(id);
          // If remote success, hard delete locally and remove from queue
          await _local.deleteCustomer(id);
          await _syncQueue.markComplete(taskId);
        } catch (e) {
          debugPrint('[KS:CUSTOMERS] Remote delete failed, tombstone kept for retry: $e');
        }
      }
    } catch (e) {
      debugPrint('[KS:CUSTOMERS] deleteCustomer failed for id=$id: $e');
    }
  }

  /// Simple Jaccard character bigram similarity for offline fuzzy name matching.
  /// Returns a score 0.0–1.0. Used as local fallback when remote trigram is unavailable.
  static double _nameSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final a2 = a.toLowerCase().trim();
    final b2 = b.toLowerCase().trim();
    // Build character bigram sets
    final bigramsA = <String>{};
    final bigramsB = <String>{};
    for (int i = 0; i < a2.length - 1; i++) { bigramsA.add(a2.substring(i, i + 2)); }
    for (int i = 0; i < b2.length - 1; i++) { bigramsB.add(b2.substring(i, i + 2)); }
    if (bigramsA.isEmpty || bigramsB.isEmpty) {
      // Fall back to character-level overlap for very short strings
      return a2.contains(b2) || b2.contains(a2) ? 0.5 : 0.0;
    }
    final intersection = bigramsA.intersection(bigramsB).length;
    final union = bigramsA.union(bigramsB).length;
    return union > 0 ? intersection / union : 0.0;
  }

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    if (await _connectivity.isConnected) {
      try {
        final models = await _remote.searchCustomers(userId: _userId, query: query);
        return models.map((m) => m.toEntity()).toList();
      } catch (e) {
        debugPrint('[KS:CUSTOMERS] Remote search failed, searching local: $e');
      }
    }
    final localModels = await _local.getCustomers();
    final q = query.toLowerCase();
    // Local: score by Jaccard bigram similarity, sort by relevance
    final scored = <({CustomerModel model, double score})>[];
    for (final m in localModels) {
      final score = _nameSimilarity(m.fullName, q);
      if (score > 0.25 || m.fullName.toLowerCase().contains(q) || m.phoneNumber.contains(q)) {
        scored.add((model: m, score: score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.model.toEntity()).toList();
  }

  @override
  Future<void> mergeCustomers(String targetId, String sourceId) async {
    final target = await _local.getCustomer(targetId);
    final source = await _local.getCustomer(sourceId);
    if (target == null || source == null) {
      throw const core_storage.StorageException(message: 'One or both customers not found.', code: 'MERGE_FAILED');
    }

    // Merge: source fills in any nulls on target
    final now = DateTime.now().toIso8601String();
    final merged = target.copyWith(
      location: target.location ?? source.location,
      notes: target.notes ?? source.notes,
      propertyType: target.propertyType ?? source.propertyType,
      leadSource: target.leadSource ?? source.leadSource,
      totalJobs: target.totalJobs + source.totalJobs,
      updatedAt: now,
    );

    await _local.saveCustomer(merged);

    // Cascade jobs from source → target
    await _jobLocal.cascadeCustomerId(sourceId, targetId);

    // Tombstone source
    await _local.tombstoneCustomer(sourceId);

    // If online: update remote
    if (await _connectivity.isConnected) {
      try {
        await _remote.updateCustomer(targetId, {
          'full_name': merged.fullName,
          'phone_number': merged.phoneNumber,
          'location': merged.location,
          'notes': merged.notes,
          'property_type': merged.propertyType,
          'lead_source': merged.leadSource,
        });
        await _remote.deleteCustomer(sourceId);
      } catch (e) {
        debugPrint('[KS:CUSTOMERS] Remote merge sync failed, queued for retry: $e');
      }
    }
  }

  @override
  Future<void> syncPendingCustomers() async {
    final pending = await _local.getPendingCustomers();
    if (pending.isEmpty) return;
    if (!await _connectivity.isConnected) return;

    final toUpserts = pending.where((c) => c.syncStatus == SyncStatus.pending).toList();
    try {
      // 1. Process deletions
      final deletions = pending.where((c) => c.syncStatus == SyncStatus.deleted).toList();
      for (final c in deletions) {
        try {
          await _remote.deleteCustomer(c.id);
          await _local.deleteCustomer(c.id);
        } catch (e) {
          debugPrint('[KS:SYNC:CUSTOMERS] Remote deletion failed for ${c.id}: $e');
        }
      }

      // 2. Process upserts
      if (toUpserts.isEmpty) return;

      final result = await _remote.batchSyncCustomers(_userId, toUpserts.map((m) => m.toJson()).toList());
      final syncedList = result['synced'] as List<dynamic>? ?? [];
      final failedList = result['failed'] as List<dynamic>? ?? [];

      // 1. Process successful syncs
      for (final syncedItem in syncedList) {
        final localId = syncedItem['local_id'] as String?;
        if (localId == null) continue;
        final serverId = syncedItem['server_id'] as String?;
        if (serverId == null) continue;
        final syncStatusStr = syncedItem['sync_status'] as String? ?? 'synced';
        final syncStatus = SyncStatus.values.firstWhere((e) => e.name == syncStatusStr, orElse: () => SyncStatus.synced);

        final originalCustomer = toUpserts.firstWhereOrNull((c) => c.id == localId);
        if (originalCustomer == null) continue;

        // Apply server-returned sync_version (server-incremented) to local record
        final serverVersion = (syncedItem['sync_version'] as num?)?.toInt();
        final updatedModel = originalCustomer.copyWith(
          id: serverId,
          syncStatus: syncStatus,
          syncVersion: serverVersion,
        );

        if (localId != serverId) {
          await _jobLocal.cascadeCustomerId(localId, serverId);
          await _local.deleteCustomer(localId);
        }
        await _local.saveCustomer(updatedModel);
      }

      // 2. Process failed syncs
      for (final failedItem in failedList) {
        final localId = failedItem['local_id'] as String;
        final errorMessage = failedItem['error'] as String?;
        final originalCustomer = toUpserts.where((c) => c.id == localId).firstOrNull;
        
        if (originalCustomer != null) {
          final failedModel = originalCustomer.copyWith(
            syncStatus: SyncStatus.failed,
            syncErrorMessage: errorMessage ?? 'Server rejection',
          );
          await _local.saveCustomer(failedModel);
        }
      }
    } catch (e) {
      debugPrint('[KS:SYNC:CUSTOMERS] FATAL ERROR: $e');
      for (final customer in toUpserts) {
        final failedModel = customer.copyWith(
          syncStatus: SyncStatus.failed,
          syncErrorMessage: e.toString(),
        );
        await _local.saveCustomer(failedModel);
      }
    }
  }
}
