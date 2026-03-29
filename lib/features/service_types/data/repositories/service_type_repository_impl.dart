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
    return localModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ServiceTypeEntity> createServiceType(ServiceTypeEntity serviceType) async {
    final model = ServiceTypeModel.fromEntity(serviceType);
    await _local.saveServiceType(model);
    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.createServiceType(model.toJson());
        await _local.saveServiceType(remoteModel);
        return remoteModel.toEntity();
      } catch (e) {
        debugPrint('[KS:SERVICE_TYPES] Remote create failed: $e');
      }
    }
    return model.toEntity();
  }

  @override
  Future<ServiceTypeEntity> updateServiceType(ServiceTypeEntity serviceType) async {
    final model = ServiceTypeModel.fromEntity(serviceType);
    await _local.saveServiceType(model);
    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.updateServiceType(serviceType.id, model.toJson());
        await _local.saveServiceType(remoteModel);
        return remoteModel.toEntity();
      } catch (e) {
        debugPrint('[KS:SERVICE_TYPES] Remote update failed: $e');
      }
    }
    return model.toEntity();
  }

  @override
  Future<void> deleteServiceType(String id) async {
    await _local.deleteServiceType(id);
    if (await _connectivity.isConnected) {
      try {
        await _remote.deleteServiceType(id);
      } catch (e) {
        debugPrint('[KS:SERVICE_TYPES] Remote delete failed: $e');
      }
    }
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
}
