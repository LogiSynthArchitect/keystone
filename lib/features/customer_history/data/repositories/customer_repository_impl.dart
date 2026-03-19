import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/storage_exception.dart' as core_storage;
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import 'package:keystone/features/job_logging/data/datasources/job_local_datasource.dart';
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

  CustomerRepositoryImpl(this._remote, this._local, this._connectivity, this._supabase, this._jobLocal);

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const core_storage.StorageException(message: 'Authentication session expired. Please log in again.', code: 'AUTH_MISSING');
    return id;
  }

  @override
  Future<List<CustomerEntity>> getCustomers({int limit = 25, int offset = 0}) async {
    if (await _connectivity.isConnected) {
      try {
        final models = await _remote.getCustomers(userId: _userId, limit: limit, offset: offset);
        for (var m in models) {
          await _local.saveCustomer(m);
        }
        return models.map((m) => m.toEntity()).toList();
      } catch (e) {
        debugPrint('[KS:CUSTOMERS] Remote fetch failed, serving from cache: $e');
      }
    }
    final localModels = await _local.getCustomers();
    return localModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CustomerEntity> getCustomerById(String id) async {
    if (await _connectivity.isConnected) {
      try {
        final models = await _remote.getCustomers(userId: _userId, limit: 1000, offset: 0);
        final match = models.firstWhere((m) => m.id == id);
        await _local.saveCustomer(match);
        return match.toEntity();
      } catch (e) {
        debugPrint('[KS:CUSTOMERS] Remote getById failed, falling back to local: $e');
      }
    }
    final localModel = await _local.getCustomer(id);
    if (localModel != null) return localModel.toEntity();
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
        return syncedModel.toEntity();
      } catch (e) {
        debugPrint('[KS:CUSTOMERS] Remote create failed, customer queued as pending: $e');
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
      createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    await _local.saveCustomer(pendingModel);

    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.updateCustomer(customer.id, {
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
        await _local.saveCustomer(syncedModel);
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

      // Attempt remote delete if connected
      if (await _connectivity.isConnected) {
        try {
          await _remote.deleteCustomer(id);
          // If remote success, we can hard delete locally
          await _local.deleteCustomer(id);
        } catch (e) {
          debugPrint('[KS:CUSTOMERS] Remote delete failed, tombstone kept for retry: $e');
        }
      }
    } catch (e) {
      debugPrint('[KS:CUSTOMERS] deleteCustomer failed for id=$id: $e');
    }
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
    return localModels
        .where((m) => m.fullName.toLowerCase().contains(q) || m.phoneNumber.contains(q))
        .map((m) => m.toEntity())
        .toList();
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
        final localId = syncedItem['local_id'] as String;
        final serverId = syncedItem['server_id'] as String;
        final syncStatusStr = syncedItem['sync_status'] as String;
        final syncStatus = SyncStatus.values.firstWhere((e) => e.name == syncStatusStr, orElse: () => SyncStatus.synced);

        final originalCustomer = toUpserts.firstWhere((c) => c.id == localId);
        final updatedModel = originalCustomer.copyWith(
          id: serverId,
          syncStatus: syncStatus,
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
