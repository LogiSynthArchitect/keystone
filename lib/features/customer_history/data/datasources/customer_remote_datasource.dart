import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/customer_model.dart';

class CustomerRemoteDatasource {
  final SupabaseClient _supabase;
  CustomerRemoteDatasource(this._supabase);

  /// Fetch customers, optionally filtered by [updatedAfter] for delta sync.
  /// When [updatedAfter] is null, fetches ALL non-deleted customers (initial seed).
  /// When [updatedAfter] is set, fetches only records with updated_at > updatedAfter.
  /// Includes soft-deleted records (deleted_at > updatedAfter) so the local
  /// cache can remove them.
  Future<List<CustomerModel>> getCustomers({
    required String userId,
    String? updatedAfter,
  }) async {
    try {
      final baseQuery = _supabase
          .from('customers')
          .select()
          .eq('user_id', userId);

      final filteredQuery = (updatedAfter != null)
          // Delta: customers updated OR deleted since last sync
          ? baseQuery.or(
              'updated_at.gt.$updatedAfter,deleted_at.gt.$updatedAfter',
            )
          // Initial full seed: only non-deleted
          : baseQuery.isFilter('deleted_at', null);

      final data = await filteredQuery.order('updated_at');
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

  /// Search customers using trigram fuzzy matching (remote) with ILIKE fallback.
  /// Results are ordered by name similarity descending.
  Future<List<CustomerModel>> searchCustomers({required String userId, required String query}) async {
    try {
      // Primary: trigram similarity search via RPC
      final data = await _supabase.rpc('search_customers_fuzzy', params: {
        'p_user_id': userId,
        'p_query': query,
        'p_limit': 20,
        'p_min_similarity': 0.3,
      });
      // RPC returns same columns as customers table + similarity_score
      return (data as List).map((e) => CustomerModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      // Fallback: ILIKE search if RPC/extension is unavailable
      debugPrint('[KS:CUSTOMERS] Fuzzy search RPC failed, falling back to ILIKE: $e');
      try {
        final data = await _supabase
            .from('customers')
            .select()
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .or('full_name.ilike.%$query%,phone_number.ilike.%$query%')
            .limit(20);
        return (data as List).map((e) => CustomerModel.fromJson(e)).toList();
      } on PostgrestException catch (e2) {
        throw NetworkException(message: 'Search failed.', code: 'SEARCH_FAILED', cause: e2);
      }
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
