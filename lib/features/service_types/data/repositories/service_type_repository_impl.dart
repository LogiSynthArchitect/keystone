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
    final model = ServiceTypeModel.fromEntity(serviceType).copyWith(
      localEditedAt: DateTime.now(),
    );
    await _local.saveServiceType(model);

    if (await _connectivity.isConnected) {
      try {
        // Use PATCH payload when correction_fields are set, full payload otherwise
        final payload = model.correctionFields.isNotEmpty ? model.toPatchJson() : model.toJson();
        final remoteModel = await _remote.updateServiceType(serviceType.id, payload);
        // Merge remote correction_fields into local state
        final merged = model.copyWith(
          correctionFields: remoteModel.correctionFields,
          updatedBy: remoteModel.updatedBy,
          localEditedAt: DateTime.now(), // preserve the local edit timestamp
        );
        await _local.saveServiceType(merged);
        return merged.toEntity();
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
      final localModels = await _local.getServiceTypes();

      // Build remote-by-UUID map for merge
      final remoteByUuid = {for (final m in remoteModels) m.id: m};

      // Preserve local services not on server (offline-created, pending sync)
      final localOnly = localModels.where((l) => !remoteByUuid.containsKey(l.id)).toList();

      // Merge remote into local by UUID (not by name)
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

      final localByUuid = {for (final m in localModels) m.id: m};
      final merged = remoteModels.map((remote) {
        final local = localByUuid[remote.id];

        // If local has pending edits (correction_fields), merge field-by-field
        if (local != null && local.correctionFields.isNotEmpty) {
          final locked = Set<String>.from(local.correctionFields);
          return ServiceTypeModel(
            id: remote.id,
            userId: remote.userId,
            name: locked.contains('name') ? local.name : remote.name,
            isDefault: locked.contains('is_default') ? local.isDefault : remote.isDefault,
            category: locked.contains('category') ? local.category : remote.category,
            iconName: locked.contains('icon_name') ? local.iconName : remote.iconName,
            defaultPrice: locked.contains('default_price') ? local.defaultPrice : remote.defaultPrice,
            createdAt: remote.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
            correctionFields: const [],
            updatedBy: remote.updatedBy,
          );
        }

        // ── localEditedAt tiebreaker ──
        // If the technician edited this record locally more recently than
        // the server's last update, preserve the local price. This prevents
        // a stale remote sync from silently reverting local adjustments.
        final remoteUpdated = DateTime.tryParse(remote.updatedAt);
        if (local != null &&
            local.localEditedAt != null &&
            remoteUpdated != null &&
            local.localEditedAt!.isAfter(remoteUpdated) &&
            local.defaultPrice != null) {
          return ServiceTypeModel(
            id: remote.id,
            userId: remote.userId,
            name: remote.name,
            isDefault: remote.isDefault,
            category: remote.category,
            iconName: remote.iconName,
            defaultPrice: local.defaultPrice,
            createdAt: remote.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
            correctionFields: const [],
            updatedBy: remote.updatedBy,
          );
        }

        // No local edits — preserve local price if remote has null
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
            correctionFields: const [],
            updatedBy: remote.updatedBy,
          );
        }
        return remote;
      }).toList();

      // Final list: merged remote items + local-only (offline-created) items
      final finalList = [...merged, ...localOnly];
      await _local.saveServiceTypes(finalList);
    } catch (e) {
      debugPrint('[KS:SERVICE_TYPES] Sync failed: $e');
    }
  }
}
