import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/constants/app_enums.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/datasources/customer_local_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/get_customer_by_phone_usecase.dart';
import '../../domain/usecases/sync_offline_customers_usecase.dart';

final customerLocalDatasourceProvider = Provider<CustomerLocalDatasource>(
  (ref) => CustomerLocalDatasource());

final customerRemoteDatasourceProvider = Provider<CustomerRemoteDatasource>(
  (ref) => CustomerRemoteDatasource(ref.watch(supabaseClientProvider)));

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService());

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepositoryImpl(
    ref.watch(customerRemoteDatasourceProvider),
    ref.watch(customerLocalDatasourceProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(jobLocalDatasourceProvider)
  ));

final getCustomersUsecaseProvider = Provider<GetCustomersUsecase>(
  (ref) => GetCustomersUsecase(ref.watch(customerRepositoryProvider)));

final getCustomerByPhoneUsecaseProvider = Provider<GetCustomerByPhoneUsecase>(
  (ref) => GetCustomerByPhoneUsecase(ref.watch(customerRepositoryProvider)));

final createCustomerUsecaseProvider = Provider<CreateCustomerUsecase>(
  (ref) => CreateCustomerUsecase(ref.watch(customerRepositoryProvider)));

final syncOfflineCustomersUsecaseProvider = Provider<SyncOfflineCustomersUsecase>(
  (ref) => SyncOfflineCustomersUsecase(ref.watch(customerRepositoryProvider)));

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
      final allCustomers = await _repository.getCustomers();
      final activeCustomers = allCustomers.where((c) => c.syncStatus == SyncStatus.synced).toList();
      state = state.copyWith(customers: activeCustomers, isLoading: false);
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
      final filteredResults = results.where((c) => c.syncStatus == SyncStatus.synced).toList();
      state = state.copyWith(searchResults: filteredResults, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, searchResults: []);
    }
  }

  void incrementJobCount(String customerId) {
    state = state.copyWith(
      customers: state.customers.map((c) => c.id == customerId 
        ? c.copyWith(totalJobs: c.totalJobs + 1) : c).toList(),
      searchResults: state.searchResults.map((c) => c.id == customerId 
        ? c.copyWith(totalJobs: c.totalJobs + 1) : c).toList(),
    );
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

final customerDetailProvider = FutureProvider.family<CustomerEntity?, String>((ref, customerId) async {
  final repo = ref.watch(customerRepositoryProvider);
  final customers = await repo.getCustomers();
  try {
    return customers.firstWhere((c) => c.id == customerId);
  } catch (_) {
    return null;
  }
});

class AddCustomerState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final bool saved;

  const AddCustomerState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.saved = false,
  });

  AddCustomerState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool? saved,
    bool clearError = false,
  }) {
    return AddCustomerState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saved: saved ?? this.saved,
    );
  }
}

class AddCustomerNotifier extends StateNotifier<AddCustomerState> {
  final CreateCustomerUsecase _createCustomer;
  final SupabaseClient _supabase;

  AddCustomerNotifier(this._createCustomer, this._supabase) : super(const AddCustomerState());

  Future<CustomerEntity?> save({
    required String fullName,
    required String phoneNumber,
    String? location,
    String? notes,
  }) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isLoading: true, isSubmitting: true, clearError: true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final customer = await _createCustomer(CreateCustomerParams(
        userId: userId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        location: location,
        notes: notes,
      ));

      state = state.copyWith(isLoading: false, isSubmitting: false, saved: true);
      return customer;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
}

final addCustomerProvider = StateNotifierProvider<AddCustomerNotifier, AddCustomerState>((ref) =>
  AddCustomerNotifier(
    ref.watch(createCustomerUsecaseProvider),
    ref.watch(supabaseClientProvider),
  ),
);
