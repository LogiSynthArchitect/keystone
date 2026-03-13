import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/analytics/ks_analytics.dart';
import '../../../../core/analytics/analytics_constants.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/get_customers_usecase.dart';

final customerRemoteDatasourceProvider = Provider<CustomerRemoteDatasource>(
  (ref) => CustomerRemoteDatasource(ref.watch(supabaseClientProvider)));

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepositoryImpl(ref.watch(customerRemoteDatasourceProvider), ref.watch(supabaseClientProvider)));

final getCustomersUsecaseProvider = Provider<GetCustomersUsecase>(
  (ref) => GetCustomersUsecase(ref.watch(customerRepositoryProvider)));

final createCustomerUsecaseProvider = Provider<CreateCustomerUsecase>(
  (ref) => CreateCustomerUsecase(ref.watch(customerRepositoryProvider)));

class CustomerListState {
  final List<CustomerEntity> customers;
  final List<CustomerEntity> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;
  final String searchQuery;
  const CustomerListState({
    this.customers = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
    this.searchQuery = '',
  });
  List<CustomerEntity> get displayed => searchQuery.isEmpty ? customers : searchResults;
  CustomerListState copyWith({
    List<CustomerEntity>? customers,
    List<CustomerEntity>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    String? searchQuery,
    bool clearError = false,
  }) => CustomerListState(
    customers: customers ?? this.customers,
    searchResults: searchResults ?? this.searchResults,
    isLoading: isLoading ?? this.isLoading,
    isSearching: isSearching ?? this.isSearching,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

class CustomerListNotifier extends StateNotifier<CustomerListState> {
  final CustomerRepository _repository;
  CustomerListNotifier(this._repository) : super(const CustomerListState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final customers = await _repository.getCustomers();
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load customers.');
    }
  }
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true);
    try {
      final results = await _repository.searchCustomers(query);
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, searchResults: []);
    }
  }
  void addCustomer(CustomerEntity customer) {
    final updated = [customer, ...state.customers]
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    state = state.copyWith(customers: updated);
  }
  Future<void> refresh() => load();
}

final customerListProvider = StateNotifierProvider<CustomerListNotifier, CustomerListState>(
  (ref) => CustomerListNotifier(ref.watch(customerRepositoryProvider)));

class AddCustomerState {
  final bool isLoading;
  final String? errorMessage;
  final bool saved;
  const AddCustomerState({this.isLoading = false, this.errorMessage, this.saved = false});
  AddCustomerState copyWith({bool? isLoading, String? errorMessage, bool? saved, bool clearError = false}) =>
    AddCustomerState(isLoading: isLoading ?? this.isLoading, errorMessage: clearError ? null : (errorMessage ?? this.errorMessage), saved: saved ?? this.saved);
}

class AddCustomerNotifier extends StateNotifier<AddCustomerState> {
  final CreateCustomerUsecase _createCustomer;
  final SupabaseClient _supabase;
  AddCustomerNotifier(this._createCustomer, this._supabase) : super(const AddCustomerState());
  Future<CustomerEntity?> save({required String fullName, required String phoneNumber, String? location, String? notes}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final customer = await _createCustomer(CreateCustomerParams(
        userId: _supabase.auth.currentUser!.id,
        fullName: fullName,
        phoneNumber: phoneNumber,
        location: location,
        notes: notes,
      ));
      state = state.copyWith(isLoading: false, saved: true);
      KsAnalytics.log(AnalyticsEvents.customerAdded, properties: {
        'has_location': location != null,
        'has_notes': notes != null,
      });
      return customer;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

final addCustomerProvider = StateNotifierProvider<AddCustomerNotifier, AddCustomerState>(
  (ref) => AddCustomerNotifier(ref.watch(createCustomerUsecaseProvider), ref.watch(supabaseClientProvider)));

final customerDetailProvider = FutureProvider.family<CustomerEntity?, String>((ref, customerId) async {
  final repo = ref.watch(customerRepositoryProvider);
  final customers = await repo.getCustomers();
  try {
    return customers.firstWhere((c) => c.id == customerId);
  } catch (_) {
    return null;
  }
});
