import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  /// Returns all locally-cached customers (instant, no network).
  Future<List<CustomerEntity>> getCustomers();

  /// Pull incremental changes from the server using delta sync.
  /// Returns number of records changed (0 if offline or up-to-date).
  Future<int> pullRemoteChanges();

  Future<CustomerEntity> getCustomerById(String id);
  Future<CustomerEntity?> getCustomerByPhone(String phoneNumber);
  Future<CustomerEntity> createCustomer(CustomerEntity customer);
  Future<CustomerEntity> updateCustomer(CustomerEntity customer);
  Future<void> deleteCustomer(String id);
  Future<List<CustomerEntity>> searchCustomers(String query);
  Future<void> syncPendingCustomers();
  Future<void> mergeCustomers(String targetId, String sourceId);
}
