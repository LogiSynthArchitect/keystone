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
          'Car Key Replacement':        25000,
          'Transponder Key Programming': 25000,
          'Car Lockout':                6500,
          'Trunk/Boot Unlock':          5000,
          'Key Fob Programming':        20000,
          'Ignition Repair':            15000,
          'Broken Key Extraction':      12000,
          'Motorcycle Keys':            15000,
          'House Lockout':              6500,
          'Lock Installation':          15000,
          'Lock Rekeying':              8000,
          'Lock Repair':                8000,
          'Key Duplication':            1500,
          'Smart Lock Install':         25000,
          'Garage Door Locks':          12000,
          'Padlock Sales/Installation': 8000,
          'Mailbox Locks':              6000,
          'Window Locks':               6000,
          'Commercial Lockout':         8000,
          'Master Key Systems':         50000,
          'Panic Bar Installation':     25000,
          'Door Closer Install':        15000,
          'Electric Strike Installation': 18000,
          'High-Security Locks':        35000,
          'File Cabinet Locks':         8000,
          'Storefront Locks':           12000,
          'CCTV Installation':          25000,
          'Video Doorbell Installation': 15000,
          'Access Control':             30000,
          'Burglar Alarms':             20000,
          'Intercom Systems':           25000,
          'Electric Gate Motor Repair': 20000,
          'Electric Fence Installation': 35000,
          'Rolling Shutter Repair':      15000,
          'Key Cutting':                1000,
          'Safe Opening':               35000,
          'Safe Installation':          25000,
          'Gate Automation':            45000,
          'Eviction Services':          30000,
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
