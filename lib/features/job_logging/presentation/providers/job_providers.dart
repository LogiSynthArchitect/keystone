import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/errors/validation_exception.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:keystone/features/customer_history/domain/repositories/customer_repository.dart';
import 'package:keystone/features/whatsapp_followup/presentation/providers/follow_up_provider.dart';
import '../../data/datasources/job_local_datasource.dart';
import '../../data/datasources/job_remote_datasource.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/repositories/job_repository.dart';
import '../../domain/usecases/get_jobs_usecase.dart';
import '../../domain/usecases/get_job_usecase.dart';
import '../../domain/usecases/log_job_usecase.dart';
import '../../domain/usecases/sync_offline_jobs_usecase.dart';
import '../../domain/usecases/archive_job_usecase.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/providers/shared_feature_providers.dart';

final jobLocalDatasourceProvider = Provider<JobLocalDatasource>((ref) => JobLocalDatasource());
final jobRemoteDatasourceProvider = Provider<JobRemoteDatasource>((ref) => JobRemoteDatasource(ref.watch(supabaseClientProvider)));
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

final jobRepositoryProvider = Provider<JobRepository>((ref) => JobRepositoryImpl(
  ref.watch(jobRemoteDatasourceProvider),
  ref.watch(jobLocalDatasourceProvider),
  ref.watch(connectivityServiceProvider),
  ref.watch(supabaseClientProvider),
  ref.watch(customerLocalDatasourceProvider),
  ref.watch(followUpRepositoryProvider),
));

final getJobsUsecaseProvider = Provider<GetJobsUsecase>((ref) => GetJobsUsecase(ref.watch(jobRepositoryProvider)));
final getJobUsecaseProvider = Provider<GetJobUsecase>((ref) => GetJobUsecase(ref.watch(jobRepositoryProvider)));
final logJobUsecaseProvider = Provider<LogJobUsecase>((ref) => LogJobUsecase(ref.watch(jobRepositoryProvider)));
final syncOfflineJobsUsecaseProvider = Provider<SyncOfflineJobsUsecase>((ref) => SyncOfflineJobsUsecase(ref.watch(jobRepositoryProvider)));
final archiveJobUsecaseProvider = Provider<ArchiveJobUsecase>((ref) => ArchiveJobUsecase(ref.watch(jobRepositoryProvider)));

final jobDetailProvider = FutureProvider.family<JobEntity?, String>((ref, jobId) async {
  final getJob = ref.watch(getJobUsecaseProvider);
  return await getJob(jobId);
});

class JobListState {
  final List<JobEntity> activeJobs;
  final List<JobEntity> allJobs;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  
  const JobListState({
    this.activeJobs = const [], 
    this.allJobs = const [], 
    this.isLoading = false, 
    this.errorMessage,
    this.searchQuery = '',
  });

  List<JobEntity> get filteredJobs {
    if (searchQuery.isEmpty) return activeJobs;
    final query = searchQuery.toLowerCase();
    return activeJobs.where((j) =>
      j.serviceType.name.toLowerCase().contains(query) ||
      (j.notes?.toLowerCase().contains(query) ?? false) ||
      (j.location?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  JobListState copyWith({
    List<JobEntity>? activeJobs, 
    List<JobEntity>? allJobs,
    bool? isLoading, 
    String? errorMessage,
    String? searchQuery,
    bool clearError = false
  }) {
    return JobListState(
      activeJobs: activeJobs ?? this.activeJobs, 
      allJobs: allJobs ?? this.allJobs,
      isLoading: isLoading ?? this.isLoading, 
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  int get totalJobs => activeJobs.length;

  double get thisMonthEarnings {
    final now = DateTime.now();
    return allJobs.where((j) =>
      j.jobDate.year == now.year &&
      j.jobDate.month == now.month
    ).fold(0.0, (sum, j) => sum + (j.amountCharged ?? 0.0));
  }
}

class JobListNotifier extends StateNotifier<JobListState> {
  final Ref _ref;
  final GetJobsUsecase _getJobs;
  final SyncOfflineJobsUsecase _syncOffline;
  final ArchiveJobUsecase _archiveJob;
  DateTime? _lastSyncTime;
  Timer? _debounce; // Task 1: Debounce Timer

  JobListNotifier(this._ref, this._getJobs, this._syncOffline, this._archiveJob) : super(const JobListState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final active = await _getJobs(const GetJobsParams(includeArchived: false));
      final all = await _getJobs(const GetJobsParams(includeArchived: true));
      state = state.copyWith(activeJobs: active, allJobs: all, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load jobs.');
    }
  }

  void setSearchQuery(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
    });
  }

  Future<void> refresh() async {
    final now = DateTime.now();
    final shouldSync = _lastSyncTime == null || now.difference(_lastSyncTime!) > const Duration(minutes: 5);
    if (shouldSync) {
      await _ref.read(syncOfflineCustomersUsecaseProvider).call();
      await _syncOffline();
      _lastSyncTime = now;
    }
    await load();
  }

  Future<void> archive(String id) async {
    try {
      await _archiveJob(id);
      _ref.invalidate(jobDetailProvider(id));
      state = state.copyWith(
        activeJobs: state.activeJobs.where((j) => j.id != id).toList(),
        allJobs: state.allJobs.map((j) => j.id == id ? j.copyWith(isArchived: true) : j).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not archive job.');
    }
  }

  void addJob(JobEntity job) {
    state = state.copyWith(
      activeJobs: [job, ...state.activeJobs],
      allJobs: [job, ...state.allJobs]
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final jobListProvider = StateNotifierProvider<JobListNotifier, JobListState>((ref) =>
  JobListNotifier(ref, ref.watch(getJobsUsecaseProvider), ref.watch(syncOfflineJobsUsecaseProvider), ref.watch(archiveJobUsecaseProvider))
);

class LogJobState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final bool saved;
  const LogJobState({this.isLoading = false, this.isSubmitting = false, this.errorMessage, this.saved = false});
  LogJobState copyWith({bool? isLoading, bool? isSubmitting, String? errorMessage, bool? saved, bool clearError = false}) {
    return LogJobState(
      isLoading: isLoading ?? this.isLoading, 
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage), 
      saved: saved ?? this.saved
    );
  }
}

class LogJobNotifier extends StateNotifier<LogJobState> {
  final Ref _ref;
  final LogJobUsecase _logJob;
  final CreateCustomerUsecase _createCustomer;
  final GetCustomerByPhoneUsecase _getCustomerByPhone;
  final SupabaseClient _supabase;
  final CustomerRepository _customerRepo;

  LogJobNotifier(this._ref, this._logJob, this._createCustomer, this._getCustomerByPhone, this._supabase, this._customerRepo) : super(const LogJobState());

  Future<JobEntity?> save({
    required ServiceType serviceType,
    String? existingCustomerId,
    String? newCustomerName,
    String? customerPhone,
    required DateTime jobDate,
    String? location,
    double? latitude,
    double? longitude,
    String? notes,
    String? amountChargedString,
  }) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isLoading: true, isSubmitting: true, clearError: true);
    String? rolledBackCustomerId;

    try {
      final userId = _supabase.auth.currentUser!.id;
      double? finalAmount;
      if (amountChargedString != null && amountChargedString.trim().isNotEmpty) {
        finalAmount = CurrencyFormatter.parse(amountChargedString);
        if (finalAmount == null) throw const ValidationException(message: "Invalid currency format.", code: "INVALID_AMOUNT");
      }

      String finalCustomerId;
      if (existingCustomerId != null) {
        finalCustomerId = existingCustomerId;
      } else if (newCustomerName != null && customerPhone != null) {
        final normalizedPhone = PhoneFormatter.normalize(customerPhone);
        final newCustomer = await _createCustomer(CreateCustomerParams(userId: userId, fullName: newCustomerName, phoneNumber: normalizedPhone, location: location));
        finalCustomerId = newCustomer.id;
        rolledBackCustomerId = finalCustomerId;
      } else {
        throw const ValidationException(message: "Customer identification missing.", code: "MISSING_CUSTOMER");
      }

      final job = await _logJob(LogJobParams(userId: userId, customerId: finalCustomerId, serviceType: serviceType, jobDate: jobDate, location: location, notes: notes, amountCharged: finalAmount));
      _ref.read(customerListProvider.notifier).incrementJobCount(finalCustomerId);

      state = state.copyWith(isLoading: false, isSubmitting: false, saved: true);
      return job;
    } catch (e) {
      if (rolledBackCustomerId != null) await _customerRepo.deleteCustomer(rolledBackCustomerId);
      state = state.copyWith(isLoading: false, isSubmitting: false, errorMessage: e is ValidationException ? e.message : e.toString());
      return null;
    }
  }
}

final logJobProvider = StateNotifierProvider<LogJobNotifier, LogJobState>((ref) => LogJobNotifier(ref, ref.watch(logJobUsecaseProvider), ref.watch(createCustomerUsecaseProvider), ref.watch(getCustomerByPhoneUsecaseProvider), ref.watch(supabaseClientProvider), ref.watch(customerRepositoryProvider)));
