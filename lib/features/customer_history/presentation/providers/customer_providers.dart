import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/duplicate_customer_exception.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/storage/hive_service.dart';
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
import '../../domain/usecases/merge_customers_usecase.dart';

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

final mergeCustomersUsecaseProvider = Provider<MergeCustomersUsecase>(
  (ref) => MergeCustomersUsecase(ref.watch(customerRepositoryProvider)));

const _kCustomerPageSize = 20;

class CustomerListState {
  final List<CustomerEntity> customers;
  final List<CustomerEntity> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;
  final String searchQuery;
  final String filterType; // 'all', 'recent', 'repeat'
  final String? propertyFilter;
  final String? leadSourceFilter;
  final int displayLimit;
  final int totalCount;
  final int repeatCount;
  final int pendingFollowUpCount;
  final int pendingSyncCount;
  final Set<String> pendingFollowUpCustomerIds;

  const CustomerListState({
    this.customers = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
    this.searchQuery = '',
    this.filterType = 'all',
    this.propertyFilter,
    this.leadSourceFilter,
    this.displayLimit = _kCustomerPageSize,
    this.totalCount = 0,
    this.repeatCount = 0,
    this.pendingFollowUpCount = 0,
    this.pendingSyncCount = 0,
    this.pendingFollowUpCustomerIds = const <String>{},
  });

  List<CustomerEntity> get displayed {
    List<CustomerEntity> base = searchQuery.isEmpty ? customers : searchResults;

    if (filterType == 'recent') {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      base = base.where((c) => c.createdAt.isAfter(weekAgo)).toList();
    } else if (filterType == 'repeat') {
      base = base.where((c) => c.totalJobs > 1).toList();
    }

    if (propertyFilter != null) {
      base = base.where((c) => c.propertyType == propertyFilter).toList();
    }

    if (leadSourceFilter != null) {
      base = base.where((c) => c.leadSource == leadSourceFilter).toList();
    }

    return base;
  }

  List<CustomerEntity> get paged => displayed.take(displayLimit).toList();
  bool get hasMore => displayed.length > displayLimit;

  /// Sentinel to distinguish "not passed" from "explicitly null".
  static const _sentinel = Object();

  CustomerListState copyWith({
    List<CustomerEntity>? customers,
    List<CustomerEntity>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    String? searchQuery,
    String? filterType,
    Object? propertyFilter = _sentinel,
    Object? leadSourceFilter = _sentinel,
    int? displayLimit,
    int? totalCount,
    int? repeatCount,
    int? pendingFollowUpCount,
    int? pendingSyncCount,
    Set<String>? pendingFollowUpCustomerIds,
    bool clearError = false,
  }) => CustomerListState(
    customers: customers ?? this.customers,
    searchResults: searchResults ?? this.searchResults,
    isLoading: isLoading ?? this.isLoading,
    isSearching: isSearching ?? this.isSearching,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    searchQuery: searchQuery ?? this.searchQuery,
    filterType: filterType ?? this.filterType,
    propertyFilter: identical(propertyFilter, _sentinel)
        ? this.propertyFilter
        : propertyFilter as String?,
    leadSourceFilter: identical(leadSourceFilter, _sentinel)
        ? this.leadSourceFilter
        : leadSourceFilter as String?,
    displayLimit: displayLimit ?? this.displayLimit,
    totalCount: totalCount ?? this.totalCount,
    repeatCount: repeatCount ?? this.repeatCount,
    pendingFollowUpCount: pendingFollowUpCount ?? this.pendingFollowUpCount,
    pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    pendingFollowUpCustomerIds: pendingFollowUpCustomerIds ?? this.pendingFollowUpCustomerIds,
  );
}

class CustomerListNotifier extends StateNotifier<CustomerListState> {
  final Ref _ref;
  final CustomerRepository _repository;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<BoxEvent>? _hiveSubscription;
  Timer? _debounceTimer;
  bool _isRefreshing = false;

  CustomerListNotifier(this._ref, this._repository) : super(const CustomerListState()) {
    load();
    _connectivitySubscription = _ref.read(connectivityServiceProvider).onConnectivityChanged.listen((isOnline) {
      if (isOnline) refresh();
    });
    // Reactive Hive listener with 200ms debounce:
    // Background sync daemon writes to Hive → this fires → reloads list
    _hiveSubscription = HiveService.customers.watch().listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        load();
      });
    });
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      var allCustomers = await _repository.getCustomers();
      // Recalculate totalJobs from local job cache (avoids denormalization drift)
      final jobLocal = _ref.read(jobLocalDatasourceProvider);
      final allJobs = await jobLocal.getJobs();
      final jobCounts = <String, int>{};
      final pendingFollowUpCustomerIds = <String>{};
      for (final job in allJobs) {
        if (!job.isArchived) {
          jobCounts[job.customerId] = (jobCounts[job.customerId] ?? 0) + 1;
        }
        // Pending follow-up = completed/invoiced job where follow-up not yet sent
        if (!job.followUpSent && (job.status == 'completed' || job.status == 'invoiced')) {
          pendingFollowUpCustomerIds.add(job.customerId);
        }
      }
      allCustomers = allCustomers.map((c) => c.copyWith(
        totalJobs: jobCounts[c.id] ?? 0,
      )).toList();

      final totalCount = allCustomers.length;
      final repeatCount = allCustomers.where((c) => c.totalJobs > 1).length;
      final pendingFollowUpCount = pendingFollowUpCustomerIds.length;
      final pendingSyncCount = allCustomers.where(
        (c) => c.syncStatus == SyncStatus.pending,
      ).length;

      state = state.copyWith(
        customers: allCustomers,
        isLoading: false,
        totalCount: totalCount,
        repeatCount: repeatCount,
        pendingFollowUpCount: pendingFollowUpCount,
        pendingSyncCount: pendingSyncCount,
        pendingFollowUpCustomerIds: pendingFollowUpCustomerIds,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load customers.');
    }
  }

  void setFilter(String type) {
    state = state.copyWith(filterType: type, displayLimit: _kCustomerPageSize);
  }

  void setPropertyFilter(String? value) {
    state = state.copyWith(propertyFilter: value, displayLimit: _kCustomerPageSize);
  }

  void setLeadSourceFilter(String? value) {
    state = state.copyWith(leadSourceFilter: value, displayLimit: _kCustomerPageSize);
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

  void decrementJobCount(String customerId) {
    if (customerId.isEmpty) return;
    state = state.copyWith(
      customers: state.customers.map((c) => c.id == customerId 
        ? c.copyWith(totalJobs: (c.totalJobs - 1).clamp(0, 999999)) : c).toList(),
      searchResults: state.searchResults.map((c) => c.id == customerId 
        ? c.copyWith(totalJobs: (c.totalJobs - 1).clamp(0, 999999)) : c).toList(),
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
    _hiveSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final customerListProvider = StateNotifierProvider<CustomerListNotifier, CustomerListState>(
  (ref) => CustomerListNotifier(ref, ref.watch(customerRepositoryProvider)));

/// Watches Hive for changes to a specific customer key.
/// Invalidates [customerDetailProvider] when background sync updates the record.
final _hiveCustomerDetailWatcher = StreamProvider.family<BoxEvent?, String>((ref, customerId) {
  return HiveService.customers.watch(key: customerId);
});

final customerDetailProvider = FutureProvider.family<CustomerEntity?, String>((ref, customerId) {
  // Subscribe to Hive changes for this specific key — makes the provider reactive
  ref.watch(_hiveCustomerDetailWatcher(customerId));
  final repo = ref.watch(customerRepositoryProvider);
  try {
    return repo.getCustomerById(customerId);
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
    String? propertyType,
    String? leadSource,
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
        propertyType: propertyType,
        leadSource: leadSource,
      ));

      state = state.copyWith(isLoading: false, isSubmitting: false, saved: true);
      return customer;
    } catch (e) {
      final msg = switch (e) {
        AppException() => e.message,
        DuplicateCustomerException() => e.message,
        _ => 'Could not save customer.',
      };
      state = state.copyWith(
        isLoading: false,
        isSubmitting: false,
        errorMessage: msg,
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
