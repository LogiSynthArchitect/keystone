import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../job_logging/data/datasources/job_local_datasource.dart';
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

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<List<CustomerEntity>> getCustomers({int limit = 25, int offset = 0}) async {
    if (await _connectivity.isConnected) {
      try {
        final models = await _remote.getCustomers(userId: _userId, limit: limit, offset: offset);
        for (var m in models) await _local.saveCustomer(m);
        return models.map((m) => m.toEntity()).toList();
      } catch (_) {}
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
      } catch (_) {}
    }
    final localModel = await _local.getCustomer(id);
    if (localModel != null) return localModel.toEntity();
    throw Exception('Customer not found');
  }

  @override
  Future<CustomerEntity?> getCustomerByPhone(String phoneNumber) async {
    if (await _connectivity.isConnected) {
      try {
        final results = await _remote.searchCustomers(userId: _userId, query: phoneNumber);
        final match = results.where((m) => m.phoneNumber == phoneNumber).firstOrNull;
        if (match != null) await _local.saveCustomer(match);
        return match?.toEntity();
      } catch (_) {}
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
      syncStatus: 'pending',
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
          syncStatus: 'synced',
          createdAt: remoteModel.createdAt,
          updatedAt: remoteModel.updatedAt,
        );

        if (localModel.id != syncedModel.id) {
          await _jobLocal.cascadeCustomerId(localModel.id, syncedModel.id);
          await _local.deleteCustomer(localModel.id);
        }

        await _local.saveCustomer(syncedModel);
        return syncedModel.toEntity();
      } catch (_) {}
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
      syncStatus: 'pending',
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
          syncStatus: 'synced',
          createdAt: remoteModel.createdAt,
          updatedAt: remoteModel.updatedAt,
        );
        await _local.saveCustomer(syncedModel);
        return syncedModel.toEntity();
      } catch (_) {}
    }
    return pendingModel.toEntity();
  }

  @override
  Future<void> deleteCustomer(String id) async {
    // Task 4: Standardize Deletion Sync - Local Always -> Remote Maybe
    try {
      final existing = await _local.getCustomer(id);
      if (existing == null) return;

      // Purge local instantly for UI responsiveness
      await _local.deleteCustomer(id);

      // Attempt remote delete if connected
      if (await _connectivity.isConnected) {
        try {
          await _remote.deleteCustomer(id);
        } catch (_) {
          // Swallow network error. If this was an offline delete, 
          // a separate background sync worker would be needed to 
          // reconcile 'deleted_at' for Customer entities.
        }
      }
    } catch (_) {}
  }

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    if (await _connectivity.isConnected) {
      try {
        final models = await _remote.searchCustomers(userId: _userId, query: query);
        return models.map((m) => m.toEntity()).toList();
      } catch (_) {}
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

    try {
      final result = await _remote.batchSyncCustomers(_userId, pending.map((m) => m.toJson()).toList());
      final syncedList = result['synced'] as List<dynamic>? ?? [];

      for (final syncedItem in syncedList) {
        final localId = syncedItem['local_id'] as String;
        final serverId = syncedItem['server_id'] as String;
        final syncStatus = syncedItem['sync_status'] as String;

        final originalCustomer = pending.firstWhere((c) => c.id == localId);
        final updatedJson = originalCustomer.toJson();
        updatedJson['id'] = serverId;
        updatedJson['sync_status'] = syncStatus;
        
        final updatedModel = CustomerModel.fromJson(updatedJson);

        if (localId != serverId) {
          await _jobLocal.cascadeCustomerId(localId, serverId);
          await _local.deleteCustomer(localId); 
        }
        await _local.saveCustomer(updatedModel);
      }
    } catch (_) {}
  }
}
