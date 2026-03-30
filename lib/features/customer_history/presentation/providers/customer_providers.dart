import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
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
import '../../domain/usecases/update_customer_usecase.dart';

final customerLocalDatasourceProvider = Provider<CustomerLocalDatasource>(
  (ref) => CustomerLocalDatasource());

final customerRemoteDatasourceProvider = Provider<CustomerRemoteDatasource>(
  (ref) => CustomerRemoteDatasource(ref.watch(supabaseClientProvider)));

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

final updateCustomerUsecaseProvider = Provider<UpdateCustomerUsecase>(
  (ref) => UpdateCustomerUsecase(ref.watch(customerRepositoryProvider)));

const _kCustomerPageSize = 20;

class CustomerListState {
  final List<CustomerEntity> customers;
  final List<CustomerEntity> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;
  final String searchQuery;
  final String filterType; // 'all', 'recent', 'repeat'
  final int displayLimit;

  const CustomerListState({
    this.customers = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
    this.searchQuery = '',
    this.filterType = 'all',
    this.displayLimit = _kCustomerPageSize,
  });

  List<CustomerEntity> get displayed {
    List<CustomerEntity> base = searchQuery.isEmpty ? customers : searchResults;

    if (filterType == 'recent') {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      base = base.where((c) => c.createdAt.isAfter(weekAgo)).toList();
    } else if (filterType == 'repeat') {
      base = base.where((c) => c.totalJobs > 1).toList();
    }

    return base;
  }

  List<CustomerEntity> get paged => displayed.take(displayLimit).toList();
  bool get hasMore => displayed.length > displayLimit;

  CustomerListState copyWith({
    List<CustomerEntity>? customers,
    List<CustomerEntity>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    String? searchQuery,
    String? filterType,
    int? displayLimit,
    bool clearError = false,
  }) => CustomerListState(
    customers: customers ?? this.customers,
    searchResults: searchResults ?? this.searchResults,
    isLoading: isLoading ?? this.isLoading,
    isSearching: isSearching ?? this.isSearching,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    searchQuery: searchQuery ?? this.searchQuery,
    filterType: filterType ?? this.filterType,
    displayLimit: displayLimit ?? this.displayLimit,
  );
}

class CustomerListNotifier extends StateNotifier<CustomerListState> {
  final Ref _ref;
  final CustomerRepository _repository;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isRefreshing = false;

  CustomerListNotifier(this._ref, this._repository) : super(const CustomerListState()) {
    load();
    _connectivitySubscription = _ref.read(connectivityServiceProvider).onConnectivityChanged.listen((isOnline) {
      if (isOnline) refresh();
    });
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final allCustomers = await _repository.getCustomers();
      state = state.copyWith(customers: allCustomers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load customers.');
    }
  }

  void setFilter(String type) {
    state = state.copyWith(filterType: type, displayLimit: _kCustomerPageSize);
  }

  void loadMore() {
    if (state.hasMore) {
      state = state.copyWith(displayLimit: state.displayLimit + _kCustomerPageSize);
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, displayLimit: _kCustomerPageSize);
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false, searchQuery: '');
      return;
    }
    state = state.copyWith(isSearching: true, clearError: true);
    try {
      final results = await _repository.searchCustomers(query);
      state = state.copyWith(searchResults: results, isSearching: false);
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
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await _ref.read(syncOfflineCustomersUsecaseProvider).call();
      await load();
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

final customerListProvider = StateNotifierProvider<CustomerListNotifier, CustomerListState>(
  (ref) => CustomerListNotifier(ref, ref.watch(customerRepositoryProvider)));

final customerDetailProvider = FutureProvider.family<CustomerEntity?, String>((ref, customerId) async {
  final repo = ref.watch(customerRepositoryProvider);
  try {
    return await repo.getCustomerById(customerId);
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

  void reset() {
    state = const AddCustomerState();
  }

  Future<CustomerEntity?> save({
    required String fullName,
    required String phoneNumber,
    String? location,
    String? notes,
  }) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isLoading: true, isSubmitting: true, clearError: true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Authentication session expired. Please log in again.');
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
