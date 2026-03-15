import '../../../../core/storage/hive_service.dart';
import '../models/customer_model.dart';

class CustomerLocalDatasource {
  Future<List<CustomerModel>> getCustomers() async {
    final box = HiveService.customers;
    return box.values.map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    final box = HiveService.customers;
    await box.put(customer.id, customer.toJson());
  }

  Future<CustomerModel?> getCustomer(String id) async {
    final box = HiveService.customers;
    final data = box.get(id);
    if (data != null) {
      return CustomerModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<CustomerModel>> getPendingCustomers() async {
    final all = await getCustomers();
    return all.where((c) => c.syncStatus == 'pending').toList();
  }

  Future<void> deleteCustomer(String id) async {
    await HiveService.customers.delete(id);
  }
}
