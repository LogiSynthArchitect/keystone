import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDatasource _remote;
  final SupabaseClient _supabase;

  CustomerRepositoryImpl(this._remote, this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<List<CustomerEntity>> getCustomers({int limit = 25, int offset = 0}) async {
    final models = await _remote.getCustomers(userId: _userId, limit: limit, offset: offset);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CustomerEntity> getCustomerById(String id) async {
    final models = await _remote.getCustomers(userId: _userId, limit: 1000, offset: 0);
    return models.firstWhere((m) => m.id == id).toEntity();
  }

  @override
  Future<CustomerEntity?> getCustomerByPhone(String phoneNumber) async {
    final results = await _remote.searchCustomers(userId: _userId, query: phoneNumber);
    final match = results.where((m) => m.phoneNumber == phoneNumber).firstOrNull;
    return match?.toEntity();
  }

  @override
  Future<CustomerEntity> createCustomer(CustomerEntity customer) async {
    final model = await _remote.createCustomer({
      'user_id': _userId,
      'full_name': customer.fullName,
      'phone_number': customer.phoneNumber,
      'location': customer.location,
      'notes': customer.notes,
    });
    return model.toEntity();
  }

  @override
  Future<CustomerEntity> updateCustomer(CustomerEntity customer) async {
    final model = await _remote.updateCustomer(customer.id, {
      'full_name': customer.fullName,
      'phone_number': customer.phoneNumber,
      'location': customer.location,
      'notes': customer.notes,
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteCustomer(String id) => _remote.deleteCustomer(id);

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    final models = await _remote.searchCustomers(userId: _userId, query: query);
    return models.map((m) => m.toEntity()).toList();
  }
}
