import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/customer_model.dart';

class CustomerRemoteDatasource {
  final SupabaseClient _supabase;
  CustomerRemoteDatasource(this._supabase);

  Future<List<CustomerModel>> getCustomers({required String userId, int limit = 25, int offset = 0}) async {
    try {
      final data = await _supabase
          .from('customers')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('full_name')
          .range(offset, offset + limit - 1);
      return (data as List).map((e) => CustomerModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load customers.', code: 'CUSTOMERS_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final data = await _supabase
        .from('customers')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return CustomerModel.fromJson(data);
  }

  Future<CustomerModel> createCustomer(Map<String, dynamic> json) async {
    if (json['user_id'] == null || (json['user_id'] as String).isEmpty) {
      throw const NetworkException(message: 'Cannot create customer: user_id is missing.', code: 'CUSTOMER_MISSING_USER_ID');
    }
    try {
      // Server-side dedup: check if phone already exists on Supabase
      // Catches duplicates when local cache is empty (fresh install / cleared data)
      final phone = json['phone_number'] as String?;
      if (phone != null && phone.isNotEmpty) {
        final existing = await _supabase
            .from('customers')
            .select()
            .eq('phone_number', phone)
            .eq('user_id', json['user_id'])
            .maybeSingle();
        if (existing != null) {
          return CustomerModel.fromJson(existing);
        }
      }

      final data = await _supabase.from('customers').insert(json).select().single();
      return CustomerModel.fromJson(data);
    } on PostgrestException catch (e) {
      // Handle Supabase unique constraint violation as fallback
      if (e.message.contains('phone_number') && e.message.contains('unique')) {
        throw NetworkException(
          message: 'A customer with this phone number already exists.',
          code: 'CUSTOMER_DUPLICATE_PHONE',
          cause: e,
        );
      }
      throw NetworkException(message: 'Could not save customer.', code: 'CUSTOMER_CREATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<CustomerModel> updateCustomer(String id, Map<String, dynamic> json) async {
    try {
      final data = await _supabase.from('customers').update(json).eq('id', id).select().single();
      return CustomerModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not update customer.', code: 'CUSTOMER_UPDATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _supabase.from('customers').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete customer.', code: 'CUSTOMER_DELETE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<List<CustomerModel>> searchCustomers({required String userId, required String query}) async {
    try {
      final data = await _supabase
          .from('customers')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .or('full_name.ilike.%$query%,phone_number.ilike.%$query%')
          .limit(20);
      return (data as List).map((e) => CustomerModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Search failed.', code: 'SEARCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<Map<String, dynamic>> batchSyncCustomers(String userId, List<Map<String, dynamic>> customers) async {
    try {
      final response = await _supabase.rpc('batch_sync_customers', params: {
        'p_user_id': userId,
        'p_customers': customers,
      });
      return response as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not sync customers.', code: 'SYNC_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }
}
