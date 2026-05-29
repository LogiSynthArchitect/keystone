import '../../../../core/storage/hive_service.dart';
import '../../../../core/constants/app_enums.dart';
import '../models/customer_model.dart';

class CustomerLocalDatasource {
  Future<List<CustomerModel>> getCustomers() async {
    final box = HiveService.customers;
    return box.values
        .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.syncStatus != SyncStatus.deleted)
        .toList();
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    final box = HiveService.customers;
    await box.put(customer.id, customer.toJson());
    await box.flush(); // Force immediate disk persistence
  }

  Future<CustomerModel?> getCustomer(String id) async {
    final box = HiveService.customers;
    final data = box.get(id);
    if (data != null) {
      final model = CustomerModel.fromJson(Map<String, dynamic>.from(data));
      return model.syncStatus == SyncStatus.deleted ? null : model;
    }
    return null;
  }

  Future<List<CustomerModel>> getPendingCustomers() async {
    final box = HiveService.customers;
    return box.values
        .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.syncStatus == SyncStatus.pending || c.syncStatus == SyncStatus.deleted)
        .toList();
  }

  Future<void> deleteCustomer(String id) async {
    // True delete from box only if it's already a tombstone or we want a hard delete
    await HiveService.customers.delete(id);
    await HiveService.customers.flush();
  }

  Future<void> tombstoneCustomer(String id) async {
    final customer = await getCustomer(id);
    if (customer != null) {
      await saveCustomer(customer.copyWith(syncStatus: SyncStatus.deleted));
    }
  }

  // ── Delta sync timestamp ──────────────────────────────────────────

  /// Returns the last successful delta sync timestamp (ISO 8601) or null
  /// if no sync has ever completed (triggers full initial fetch).
  String? getLastSyncTimestamp() {
    final box = HiveService.meta;
    return box.get(HiveService.lastOnlineSyncKey) as String?;
  }

  /// Persists the current UTC timestamp after a successful delta sync.
  /// Optionally accepts an explicit [timestamp] for seeding on upgrade.
  Future<void> setLastSyncTimestamp([String? timestamp]) async {
    final box = HiveService.meta;
    await box.put(HiveService.lastOnlineSyncKey, timestamp ?? DateTime.now().toUtc().toIso8601String());
    await box.flush();
  }
}
