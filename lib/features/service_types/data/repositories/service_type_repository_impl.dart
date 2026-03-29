import 'package:flutter/foundation.dart';
import '../../../../core/network/connectivity_service.dart';
import '../datasources/service_type_local_datasource.dart';
import '../datasources/service_type_remote_datasource.dart';
import '../../domain/entities/service_type_entity.dart';
import '../models/service_type_model.dart';
import '../../domain/repositories/service_type_repository.dart';

class ServiceTypeRepositoryImpl implements ServiceTypeRepository {
  final ServiceTypeRemoteDatasource _remote;
  final ServiceTypeLocalDatasource _local;
  final ConnectivityService _connectivity;

  ServiceTypeRepositoryImpl(this._remote, this._local, this._connectivity);

  @override
  Future<List<ServiceTypeEntity>> getServiceTypes() async {
    if (await _connectivity.isConnected) {
      await syncServiceTypes();
    }

    final localModels = await _local.getServiceTypes();
    if (localModels.isEmpty) {
      return _getV1Defaults();
    }

    return localModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ServiceTypeEntity> createServiceType(ServiceTypeEntity serviceType) async {
    final model = ServiceTypeModel.fromEntity(serviceType);
    final remoteModel = await _remote.createServiceType(model.toJson());
    await _local.saveServiceTypes([remoteModel]);
    return remoteModel.toEntity();
  }

  @override
  Future<void> syncServiceTypes() async {
    try {
      final remoteModels = await _remote.getServiceTypes();
      await _local.clear();
      await _local.saveServiceTypes(remoteModels);
    } catch (e) {
      debugPrint('[KS:SERVICE_TYPES] Sync failed: $e');
    }
  }

  List<ServiceTypeEntity> _getV1Defaults() {
    final now = DateTime.now();
    return [
      ServiceTypeEntity(id: 'v1_1', userId: 'system', name: 'Car Key Programming', slug: 'car_lock_programming', displayOrder: 10, createdAt: now, updatedAt: now),
      ServiceTypeEntity(id: 'v1_2', userId: 'system', name: 'Door Lock Installation', slug: 'door_lock_installation', displayOrder: 20, createdAt: now, updatedAt: now),
      ServiceTypeEntity(id: 'v1_3', userId: 'system', name: 'Door Lock Repair', slug: 'door_lock_repair', displayOrder: 30, createdAt: now, updatedAt: now),
      ServiceTypeEntity(id: 'v1_4', userId: 'system', name: 'Smart Lock Installation', slug: 'smart_lock_installation', displayOrder: 40, createdAt: now, updatedAt: now),
    ];
  }
}
