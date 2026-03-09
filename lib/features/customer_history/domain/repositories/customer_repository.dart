import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<List<CustomerEntity>> getCustomers({int limit = 25, int offset = 0});
  Future<CustomerEntity> getCustomerById(String id);
  Future<CustomerEntity?> getCustomerByPhone(String phoneNumber);
  Future<CustomerEntity> createCustomer(CustomerEntity customer);
  Future<CustomerEntity> updateCustomer(CustomerEntity customer);
  Future<void> deleteCustomer(String id);
  Future<List<CustomerEntity>> searchCustomers(String query);
}
