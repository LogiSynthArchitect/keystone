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
      if (remoteModels.isNotEmpty) {
        // Preserve local defaultPrice when remote has null;
        // also apply default prices for common service types
        const defaultPrices = {
          'deadbolt_replacement': 15000,
          'car_key_programming':   25000,
          'smart_lock_installation': 25000,
          'door_lock_installation': 15000,
          'door_lock_repair':     8000,
          'lockout_assistance':   6500,
          'safe_opening':         35000,
          'master_key_system':    50000,
          'cabinet_locks':        12000,
          'gate_automation':      45000,
          'window_lock_repair':   6000,
          'key_duplication':      1500,
          'lock_rekeying':        8000,
          'gate_remote_programming': 12000,
          'emergency_lockout':    8000,
          'master_key_blank':     3000,
          'lock_lubrication':     4500,
          'remote_battery':        800,
        };

        final localModels = await _local.getServiceTypes();
        await _local.clear();
        final merged = remoteModels.map((remote) {
          final local = localModels.where((l) => l.name == remote.name).firstOrNull;
          final existingPrice = local?.defaultPrice;
          final price = existingPrice ?? defaultPrices[remote.name];
          if (price != null && price != remote.defaultPrice) {
            return ServiceTypeModel(
              id: remote.id,
              userId: remote.userId,
              name: remote.name,
              isDefault: remote.isDefault,
              category: remote.category,
              iconName: remote.iconName,
              defaultPrice: price,
              createdAt: remote.createdAt,
              updatedAt: DateTime.now().toIso8601String(),
            );
          }
          return remote;
        }).toList();
        await _local.saveServiceTypes(merged);
      }
    } catch (e) {
      debugPrint('[KS:SERVICE_TYPES] Sync failed: $e');
    }
  }
}
