import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/errors/validation_exception.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/services/pending_media_upload_service.dart';
import 'package:keystone/features/whatsapp_followup/presentation/providers/follow_up_provider.dart';
import '../../data/datasources/job_local_datasource.dart';
import '../../data/datasources/job_remote_datasource.dart';
import '../../data/datasources/job_parts_local_datasource.dart';
import '../../data/datasources/job_parts_remote_datasource.dart';
import '../../data/datasources/job_photos_local_datasource.dart';
import '../../data/datasources/job_photos_remote_datasource.dart';
import '../../data/datasources/job_audit_local_datasource.dart';
import '../../data/datasources/job_audit_remote_datasource.dart';
import '../../data/datasources/job_services_local_datasource.dart';
import '../../data/datasources/job_services_remote_datasource.dart';
import '../../data/datasources/job_hardware_local_datasource.dart';
import '../../data/datasources/job_hardware_remote_datasource.dart';
import '../../data/datasources/job_expenses_local_datasource.dart';
import '../../data/datasources/job_expenses_remote_datasource.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/entities/job_part_entity.dart';
import '../../domain/entities/job_photo_entity.dart';
import '../../domain/entities/job_audit_entry_entity.dart';
import '../../domain/entities/job_service_entity.dart';
import '../../domain/entities/job_hardware_entity.dart';
import '../../domain/entities/job_expense_entity.dart';
import '../../domain/repositories/job_repository.dart';
import '../../domain/usecases/get_jobs_usecase.dart';
import '../../domain/usecases/get_job_usecase.dart';
import '../../domain/usecases/log_job_usecase.dart';
import '../../domain/usecases/sync_offline_jobs_usecase.dart';
import '../../domain/usecases/archive_job_usecase.dart';
import '../../domain/usecases/log_job_with_customer_usecase.dart';
import '../../domain/usecases/edit_job_usecase.dart';
import '../../domain/usecases/update_payment_status_usecase.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import 'package:keystone/features/inventory/presentation/providers/inventory_providers.dart';

import '../../domain/entities/correction_request_entity.dart';
import '../../domain/repositories/correction_request_repository.dart';
import '../../data/repositories/correction_request_repository_impl.dart';
import '../../domain/usecases/request_correction_usecase.dart';
import '../../data/models/job_part_model.dart';
import '../../data/models/job_photo_model.dart';

final jobLocalDatasourceProvider = Provider<JobLocalDatasource>((ref) => JobLocalDatasource());
final jobRemoteDatasourceProvider = Provider<JobRemoteDatasource>((ref) => JobRemoteDatasource(ref.watch(supabaseClientProvider)));

final jobPartsLocalDatasourceProvider = Provider<JobPartsLocalDatasource>((ref) => JobPartsLocalDatasource());
final jobPartsRemoteDatasourceProvider = Provider<JobPartsRemoteDatasource>((ref) => JobPartsRemoteDatasource(ref.watch(supabaseClientProvider)));

final jobPhotosLocalDatasourceProvider = Provider<JobPhotosLocalDatasource>((ref) => JobPhotosLocalDatasource());
final jobPhotosRemoteDatasourceProvider = Provider<JobPhotosRemoteDatasource>((ref) => JobPhotosRemoteDatasource(ref.watch(supabaseClientProvider)));

final jobAuditLocalDatasourceProvider = Provider<JobAuditLocalDatasource>((ref) => JobAuditLocalDatasource());
final jobAuditRemoteDatasourceProvider = Provider<JobAuditRemoteDatasource>((ref) => JobAuditRemoteDatasource(ref.watch(supabaseClientProvider)));

final jobServicesLocalDatasourceProvider = Provider<JobServicesLocalDatasource>((ref) => JobServicesLocalDatasource());
final jobServicesRemoteDatasourceProvider = Provider<JobServicesRemoteDatasource>((ref) => JobServicesRemoteDatasource(ref.watch(supabaseClientProvider)));

final jobHardwareLocalDatasourceProvider = Provider<JobHardwareLocalDatasource>((ref) => JobHardwareLocalDatasource());
final jobHardwareRemoteDatasourceProvider = Provider<JobHardwareRemoteDatasource>((ref) => JobHardwareRemoteDatasource(ref.watch(supabaseClientProvider)));

final jobExpensesLocalDatasourceProvider = Provider<JobExpensesLocalDatasource>((ref) => JobExpensesLocalDatasource());
final jobExpensesRemoteDatasourceProvider = Provider<JobExpensesRemoteDatasource>((ref) => JobExpensesRemoteDatasource(ref.watch(supabaseClientProvider)));

final jobRepositoryProvider = Provider<JobRepository>((ref) => JobRepositoryImpl(
  ref.watch(jobRemoteDatasourceProvider),
  ref.watch(jobLocalDatasourceProvider),
  ref.watch(connectivityServiceProvider),
  ref.watch(supabaseClientProvider),
  ref.watch(customerLocalDatasourceProvider),
  ref.watch(followUpRepositoryProvider),
  ref.watch(jobPartsLocalDatasourceProvider),
  ref.watch(jobPartsRemoteDatasourceProvider),
  ref.watch(jobPhotosLocalDatasourceProvider),
  ref.watch(jobPhotosRemoteDatasourceProvider),
  ref.watch(jobAuditLocalDatasourceProvider),
  ref.watch(jobAuditRemoteDatasourceProvider),
  ref.watch(jobServicesLocalDatasourceProvider),
  ref.watch(jobServicesRemoteDatasourceProvider),
  ref.watch(jobHardwareLocalDatasourceProvider),
  ref.watch(jobHardwareRemoteDatasourceProvider),
  ref.watch(jobExpensesLocalDatasourceProvider),
  ref.watch(jobExpensesRemoteDatasourceProvider),
));

final correctionRequestRepositoryProvider = Provider<CorrectionRequestRepository>((ref) =>
  CorrectionRequestRepositoryImpl(ref.watch(supabaseClientProvider)));

final getJobsUsecaseProvider = Provider<GetJobsUsecase>((ref) => GetJobsUsecase(ref.watch(jobRepositoryProvider)));
final getJobUsecaseProvider = Provider<GetJobUsecase>((ref) => GetJobUsecase(ref.watch(jobRepositoryProvider)));
final logJobUsecaseProvider = Provider<LogJobUsecase>((ref) => LogJobUsecase(ref.watch(jobRepositoryProvider), ref.watch(customerRepositoryProvider)));
final syncOfflineJobsUsecaseProvider = Provider<SyncOfflineJobsUsecase>((ref) => SyncOfflineJobsUsecase(ref.watch(jobRepositoryProvider)));
final archiveJobUsecaseProvider = Provider<ArchiveJobUsecase>((ref) => ArchiveJobUsecase(ref.watch(jobRepositoryProvider)));
final editJobUsecaseProvider = Provider<EditJobUsecase>((ref) => EditJobUsecase(ref.watch(jobRepositoryProvider)));
final updatePaymentStatusUsecaseProvider = Provider<UpdatePaymentStatusUsecase>((ref) => UpdatePaymentStatusUsecase(ref.watch(jobRepositoryProvider)));
final requestCorrectionUsecaseProvider = Provider<RequestCorrectionUsecase>((ref) => RequestCorrectionUsecase(ref.watch(correctionRequestRepositoryProvider)));

final adminRequestsProvider = FutureProvider<List<CorrectionRequestEntity>>((ref) async {
  return await ref.watch(correctionRequestRepositoryProvider).getAllPendingRequests();
});

class AdminRequestsNotifier extends StateNotifier<AsyncValue<void>> {
  final CorrectionRequestRepository _repo;
  final Ref _ref;

  AdminRequestsNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> approve(String requestId, String jobId, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      await _repo.approveRequest(requestId, jobId, updates);
      _ref.invalidate(adminRequestsProvider);
      _ref.invalidate(jobDetailProvider(jobId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reject(String requestId, {String? adminNotes}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectRequest(requestId, adminNotes: adminNotes);
      _ref.invalidate(adminRequestsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminRequestsActionProvider = StateNotifierProvider<AdminRequestsNotifier, AsyncValue<void>>((ref) =>
  AdminRequestsNotifier(ref.watch(correctionRequestRepositoryProvider), ref)
);

final logJobWithCustomerUsecaseProvider = Provider<LogJobWithCustomerUsecase>(
  (ref) => LogJobWithCustomerUsecase(
    ref.watch(logJobUsecaseProvider),
    ref.watch(createCustomerUsecaseProvider),
    ref.watch(customerRepositoryProvider),
  ),
);

class JobDetailData {
  final JobEntity? job;
  final List<JobPartEntity> parts;
  final List<JobPhotoEntity> photos;
  final List<JobAuditEntryEntity> auditLog;
  final List<JobServiceEntity> services;
  final List<JobHardwareEntity> hardware;
  final String? error;

  const JobDetailData({
    this.job,
    this.parts = const [],
    this.photos = const [],
    this.auditLog = const [],
    this.services = const [],
    this.hardware = const [],
    this.error,
  });

  bool get isLoading => job == null && error == null;
}

final jobDetailProvider = FutureProvider.family<JobEntity?, String>((ref, jobId) async {
  final getJob = ref.watch(getJobUsecaseProvider);
  return await getJob(jobId);
});

final jobDetailCompositeProvider = FutureProvider.family<JobDetailData, String>((ref, jobId) async {
  try {
    final repo = ref.watch(jobRepositoryProvider);
    final results = await Future.wait([
      repo.getJobById(jobId),
      repo.getPartsForJob(jobId),
      repo.getPhotosForJob(jobId),
      repo.getAuditLogForJob(jobId),
      repo.getServicesForJob(jobId),
      repo.getHardwareForJob(jobId),
    ]);
    return JobDetailData(
      job: results[0] as JobEntity?,
      parts: results[1] as List<JobPartEntity>,
      photos: results[2] as List<JobPhotoEntity>,
      auditLog: results[3] as List<JobAuditEntryEntity>,
      services: results[4] as List<JobServiceEntity>,
      hardware: results[5] as List<JobHardwareEntity>,
    );
  } catch (e) {
    return JobDetailData(error: e.toString());
  }
});

final jobPartsProvider = FutureProvider.family<List<JobPartEntity>, String>((ref, jobId) async {
  return await ref.watch(jobRepositoryProvider).getPartsForJob(jobId);
});

final jobPhotosProvider = FutureProvider.family<List<JobPhotoEntity>, String>((ref, jobId) async {
  return await ref.watch(jobRepositoryProvider).getPhotosForJob(jobId);
});

final jobAuditLogProvider = FutureProvider.family<List<JobAuditEntryEntity>, String>((ref, jobId) async {
  return await ref.watch(jobRepositoryProvider).getAuditLogForJob(jobId);
});

final jobServicesProvider = FutureProvider.family<List<JobServiceEntity>, String>((ref, jobId) async {
  return await ref.watch(jobRepositoryProvider).getServicesForJob(jobId);
});

final jobHardwareProvider = FutureProvider.family<List<JobHardwareEntity>, String>((ref, jobId) async {
  return await ref.watch(jobRepositoryProvider).getHardwareForJob(jobId);
});

final jobExpensesProvider = FutureProvider.family<List<JobExpenseEntity>, String>((ref, jobId) async {
  return await ref.watch(jobRepositoryProvider).getExpensesForJob(jobId);
});

class JobListFilters {
  final String? status;           // 'quoted' | 'in_progress' | 'completed' | 'invoiced'
  final String? paymentStatus;    // 'unpaid' | 'partial' | 'paid'
  final String? serviceType;
  final DateTimeRange? dateRange;

  const JobListFilters({
    this.status,
    this.paymentStatus,
    this.serviceType,
    this.dateRange,
  });

  bool get hasActive =>
      status != null || paymentStatus != null || serviceType != null || dateRange != null;

  int get activeCount => [status, paymentStatus, serviceType, if (dateRange != null) 'date']
      .where((v) => v != null).length;

  JobListFilters copyWith({
    Object? status = _sentinel,
    Object? paymentStatus = _sentinel,
    Object? serviceType = _sentinel,
    Object? dateRange = _sentinel,
  }) {
    return JobListFilters(
      status: status == _sentinel ? this.status : status as String?,
      paymentStatus: paymentStatus == _sentinel ? this.paymentStatus : paymentStatus as String?,
      serviceType: serviceType == _sentinel ? this.serviceType : serviceType as String?,
      dateRange: dateRange == _sentinel ? this.dateRange : dateRange as DateTimeRange?,
    );
  }
}

const _sentinel = Object();

const _kPageSize = 20;

class JobListState {
  final List<JobEntity> activeJobs;
  final List<JobEntity> allJobs;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool isSyncing;
  final JobListFilters filters;
  final int displayLimit;

  const JobListState({
    this.activeJobs = const [],
    this.allJobs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.isSyncing = false,
    this.filters = const JobListFilters(),
    this.displayLimit = _kPageSize,
  });

  List<JobEntity> get filteredJobs {
    var jobs = activeJobs;

    // Text search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      jobs = jobs.where((j) =>
        j.serviceType.toLowerCase().contains(query) ||
        (j.notes?.toLowerCase().contains(query) ?? false) ||
        (j.location?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Status filter
    if (filters.status != null) {
      jobs = jobs.where((j) => j.status == filters.status).toList();
    }

    // Payment status filter
    if (filters.paymentStatus != null) {
      jobs = jobs.where((j) => j.paymentStatus == filters.paymentStatus).toList();
    }

    // Service type filter
    if (filters.serviceType != null) {
      jobs = jobs.where((j) => j.serviceType == filters.serviceType).toList();
    }

    // Date range filter
    if (filters.dateRange != null) {
      final range = filters.dateRange!;
      jobs = jobs.where((j) =>
        !j.jobDate.isBefore(range.start) &&
        !j.jobDate.isAfter(range.end)
      ).toList();
    }

    return jobs;
  }

  List<JobEntity> get pagedJobs => filteredJobs.take(displayLimit).toList();
  bool get hasMore => filteredJobs.length > displayLimit;

  JobListState copyWith({
    List<JobEntity>? activeJobs,
    List<JobEntity>? allJobs,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? isSyncing,
    JobListFilters? filters,
    int? displayLimit,
    bool clearError = false
  }) {
    return JobListState(
      activeJobs: activeJobs ?? this.activeJobs,
      allJobs: allJobs ?? this.allJobs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      isSyncing: isSyncing ?? this.isSyncing,
      filters: filters ?? this.filters,
      displayLimit: displayLimit ?? this.displayLimit,
    );
  }

int get totalJobs => activeJobs.length;

int get pendingCount => allJobs.where((j) => j.syncStatus == SyncStatus.pending).length;

int get thisMonthEarnings {
  final now = DateTime.now();
  final thisMonthJobs = allJobs.where((j) {
    return j.jobDate.year == now.year &&
           j.jobDate.month == now.month &&
           j.amountCharged != null;
  });
  return thisMonthJobs.fold<int>(0, (sum, j) => sum + j.amountCharged!);
}

/// Filter-aware earnings — reflects whatever filters are active.
int get filteredEarnings {
  return filteredJobs
      .where((j) => j.amountCharged != null)
      .fold<int>(0, (sum, j) => sum + j.amountCharged!);
}

/// Filter-aware job count.
int get filteredJobCount => filteredJobs.length;

/// Human-readable label for the current filter context.
String get summaryLabel {
  if (filters.dateRange != null) {
    final r = filters.dateRange!;
    final start = r.start;
    final end = r.end;
    if (start.month == end.month && start.year == end.year) {
      return DateFormat('MMMM yyyy').format(start).toUpperCase();
    }
    return '${start.day}/${start.month} \u2192 ${end.day}/${end.month}';
  }
  return 'THIS MONTH';
}
}

class JobListNotifier extends StateNotifier<JobListState> {
  final Ref _ref;
  final GetJobsUsecase _getJobs;
  final SyncOfflineJobsUsecase _syncOffline;
  final ArchiveJobUsecase _archiveJob;
  Timer? _debounce;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isRefreshing = false;

  JobListNotifier(this._ref, this._getJobs, this._syncOffline, this._archiveJob) : super(const JobListState()) {
    load();
    _connectivitySubscription = _ref.read(connectivityServiceProvider).onConnectivityChanged.listen((isOnline) {
      if (isOnline) refresh();
    });
  }

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
      state = state.copyWith(searchQuery: query, displayLimit: _kPageSize);
    });
  }

  void setFilters(JobListFilters filters) {
    state = state.copyWith(filters: filters, displayLimit: _kPageSize);
  }

  void clearFilters() {
    state = state.copyWith(filters: const JobListFilters(), displayLimit: _kPageSize);
  }

  void loadMore() {
    if (state.hasMore) {
      state = state.copyWith(displayLimit: state.displayLimit + _kPageSize);
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    state = state.copyWith(isSyncing: true);
    try {
      await _ref.read(syncOfflineCustomersUsecaseProvider).call();
      await _syncOffline();
      await load();
    } finally {
      _isRefreshing = false;
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> archive(String id) async {
    try {
      final job = state.activeJobs.where((j) => j.id == id).firstOrNull;
      final customerId = job?.customerId;

      await _archiveJob(id);

      if (customerId != null && customerId.isNotEmpty) {
        try {
          _ref.read(customerListProvider.notifier).decrementJobCount(customerId);
        } catch (_) {}
      }

      // Restore stock for auto-cogs inventory items
      try {
        final user = await _ref.read(currentUserProvider.future);
        if (user != null) {
          final invRepo = _ref.read(inventoryRepositoryProvider);
          final allInv = await invRepo.getItems(user.id);
          final jobRepo = _ref.read(jobRepositoryProvider);

          // Restore parts stock
          final jobParts = await jobRepo.getPartsForJob(id);
          for (final part in jobParts) {
            final matches = part.inventoryItemId != null
              ? allInv.where((i) => i.id == part.inventoryItemId && i.isAutoCogs).toList()
              : allInv.where((i) =>
                  i.isAutoCogs &&
                  i.name.toLowerCase() == part.partName.toLowerCase()
                ).toList();
            for (final item in matches) {
              await invRepo.adjustStock(
                item.id, user.id, part.quantity ?? 1, 'job_unarchive',
                reason: 'Restored from archived job ${id.substring(0, 8)}',
                referenceType: 'job_archive',
                referenceId: id,
              );
            }
          }

          // Restore hardware stock (matches by brand name)
          final jobHardware = await jobRepo.getHardwareForJob(id);
          for (final hw in jobHardware) {
            final brand = hw.brand;
            if (brand == null || brand.isEmpty) continue;
            final matches = allInv.where((i) =>
              i.isAutoCogs &&
              i.name.toLowerCase() == brand.toLowerCase()
            ).toList();
            for (final item in matches) {
              await invRepo.adjustStock(
                item.id, user.id, hw.quantity, 'job_unarchive',
                reason: 'Hardware restored from archived job ${id.substring(0, 8)}',
                referenceType: 'job_archive',
                referenceId: id,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('[KS:INVENTORY] Stock restoration on archive failed: $e');
      }

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

  Future<void> toggleFollowUpSent(String jobId, bool sent) async {
    try {
      final repo = _ref.read(jobRepositoryProvider);
      final existingJob = await repo.getJobById(jobId);
      if (existingJob == null) return;
      final updatedJob = existingJob.copyWith(followUpSent: sent);
      await repo.updateJob(updatedJob);
      
      _ref.invalidate(jobDetailProvider(jobId));
      state = state.copyWith(
        activeJobs: state.activeJobs.map((j) => j.id == jobId ? updatedJob : j).toList(),
        allJobs: state.allJobs.map((j) => j.id == jobId ? updatedJob : j).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not update follow-up state.');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

final jobListProvider = StateNotifierProvider<JobListNotifier, JobListState>((ref) =>
  JobListNotifier(ref, ref.watch(getJobsUsecaseProvider), ref.watch(syncOfflineJobsUsecaseProvider), ref.watch(archiveJobUsecaseProvider))
);

/// User-configurable monthly revenue target, persisted in Hive settings.
final monthlyTargetProvider = StateProvider<int>((ref) {
  final saved = HiveService.settings.get('monthlyTarget');
  return (saved is int && saved > 0) ? saved : 800000;
});

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
  final LogJobWithCustomerUsecase _logJobWithCustomer;
  final JobPartsLocalDatasource _partsLocal;
  final JobPhotosLocalDatasource _photosLocal;

  LogJobNotifier(this._ref, this._logJobWithCustomer, this._partsLocal, this._photosLocal) : super(const LogJobState());

  void reset() => state = const LogJobState();

  Future<JobEntity?> save({
    required String serviceType,
    String? existingCustomerId,
    String? newCustomerName,
    String? customerPhone,
    required DateTime jobDate,
    String? location,
    double? latitude,
    double? longitude,
    String? notes,
    String? amountChargedString,
    String status = 'in_progress',
    String paymentStatus = 'unpaid',
    String? quotedPriceString,
    String? leadSource,
    List<(String, int, int, String?)>? parts, // name, qty, price, inventoryItemId
    List<(String?, String, int, String?)>? hardwareItems, // inventoryItemId, name, qty, inventoryItemId (dup for pattern) 
    List<(File, String, String)>? photos, // file, label, mediaType
  }) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isLoading: true, isSubmitting: true, clearError: true);

    try {
      final user = await _ref.read(currentUserProvider.future);
      final userId = user?.id;
      if (userId == null) throw Exception('Authentication session expired. Please log in again.');
      
      int? finalAmount;
      if (amountChargedString != null && amountChargedString.trim().isNotEmpty) {
        finalAmount = CurrencyFormatter.parseToPesewas(amountChargedString);
        if (finalAmount == null) throw const ValidationException(message: "Invalid currency format for final amount.", code: "INVALID_AMOUNT");
      }

      int? quotedPrice;
      if (quotedPriceString != null && quotedPriceString.trim().isNotEmpty) {
        quotedPrice = CurrencyFormatter.parseToPesewas(quotedPriceString);
        if (quotedPrice == null) throw const ValidationException(message: "Invalid currency format for quoted price.", code: "INVALID_QUOTED_PRICE");
      }

      final job = await _logJobWithCustomer(LogJobWithCustomerParams(
        userId: userId,
        serviceType: serviceType,
        jobDate: jobDate,
        existingCustomerId: existingCustomerId,
        newCustomerName: newCustomerName,
        customerPhone: customerPhone,
        location: location,
        notes: notes,
        amountCharged: finalAmount,
        status: status,
        paymentStatus: paymentStatus,
        quotedPrice: quotedPrice != null ? quotedPrice / 100.0 : null,
        leadSource: leadSource,
      ));

      // Save parts locally
      if (parts != null && parts.isNotEmpty) {
        final partModels = parts.map((p) => JobPartModel(
          id: const Uuid().v4(),
          jobId: job.id,
          partName: p.$1,
          quantity: p.$2,
          unitPrice: p.$3,
          inventoryItemId: p.$4,
          createdAt: DateTime.now().toIso8601String(),
        )).toList();
        await _partsLocal.saveAll(partModels);

        // Auto-deduct inventory for auto-cogs items
        // Uses inventory_item_id for exact match, falls back to name match
        try {
          final invRepo = _ref.read(inventoryRepositoryProvider);
          final allInv = await invRepo.getItems(userId);
          for (final p in parts) {
            final invId = p.$4;
            final matches = invId != null
              ? allInv.where((i) => i.id == invId && i.isAutoCogs).toList()
              : allInv.where((i) =>
                  i.isAutoCogs &&
                  i.name.toLowerCase() == p.$1.toLowerCase()
                ).toList();
            for (final item in matches) {
              await invRepo.adjustStock(
                item.id, userId, -p.$2, 'job_use',
                reason: 'Auto-COGS: ${p.$1} used in job ${job.id.substring(0, 8)}',
                referenceType: 'job',
                referenceId: job.id,
              );
            }
          }
        } catch (e) {
          debugPrint('[KS:INVENTORY] Auto-COGS deduction failed: $e');
        }

        // Auto-deduct inventory for auto-cogs hardware items
        if (hardwareItems != null && hardwareItems.isNotEmpty) {
          try {
            final invRepo = _ref.read(inventoryRepositoryProvider);
            final allInv = await invRepo.getItems(userId);
            for (final hw in hardwareItems) {
              final invId = hw.$1;
              if (invId == null) continue;
              final matches = allInv.where((i) =>
                i.id == invId && i.isAutoCogs
              ).toList();
              for (final item in matches) {
                final qty = hw.$3;
                await invRepo.adjustStock(
                  item.id, userId, -qty, 'job_use',
                  reason: 'Auto-COGS: ${hw.$2} used in job ${job.id.substring(0, 8)}',
                  referenceType: 'job',
                  referenceId: job.id,
                );
              }
            }
          } catch (e) {
            debugPrint('[KS:INVENTORY] Hardware auto-COGS deduction failed: $e');
          }
        }
      }

      // Save photos locally and queue for upload
      if (photos != null && photos.isNotEmpty) {
        for (var p in photos) {
          final photoId = const Uuid().v4();
          await _photosLocal.savePhoto(JobPhotoModel(
            id: photoId,
            jobId: job.id,
            storagePath: p.$1.path,
            label: p.$2,
            mediaType: p.$3,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }

        // Enqueue pending uploads for retry when online
        try {
          final svc = PendingMediaUploadService();
          for (var p in photos) {
            await svc.enqueue(PendingMediaUpload(
              id: const Uuid().v4(),
              filePath: p.$1.path,
              jobId: job.id,
              userId: userId,
              mediaType: p.$3,
              label: p.$2,
              createdAt: DateTime.now(),
            ));
          }
        } catch (e) {
          debugPrint('[KS:PHOTOS] Failed to enqueue pending uploads: $e');
        }
      }
      
      _ref.read(customerListProvider.notifier).incrementJobCount(job.customerId);
      await _ref.read(customerListProvider.notifier).refresh();

      _ref.read(jobListProvider.notifier).addJob(job);
      await _ref.read(jobListProvider.notifier).refresh();
      await HapticFeedback.mediumImpact();

      state = state.copyWith(isLoading: false, isSubmitting: false, saved: true);
      return job;
    } catch (e) {
      state = state.copyWith(isLoading: false, isSubmitting: false, errorMessage: e is ValidationException ? e.message : e.toString());
      return null;
    }
  }
}

final logJobProvider = StateNotifierProvider<LogJobNotifier, LogJobState>((ref) => LogJobNotifier(
  ref, 
  ref.watch(logJobWithCustomerUsecaseProvider),
  ref.watch(jobPartsLocalDatasourceProvider),
  ref.watch(jobPhotosLocalDatasourceProvider),
));

class CustomerHistorySuggestions {
  final Set<String> hardwareBrands;
  final Set<String> hardwareKeyways;
  final Set<String> partNames;

  const CustomerHistorySuggestions({
    this.hardwareBrands = const {},
    this.hardwareKeyways = const {},
    this.partNames = const {},
  });
}

final customerHistorySuggestionsProvider = FutureProvider.family<CustomerHistorySuggestions, String>((ref, customerId) async {
  final local = ref.watch(jobLocalDatasourceProvider);
  final allJobs = await local.getJobs();
  final pastJobs = allJobs.where((j) => j.customerId == customerId).toList();

  final brands = <String>{};
  final keyways = <String>{};
  final partNames = <String>{};

  for (final job in pastJobs) {
    final entity = job.toEntity();
    if (entity.hardwareBrand != null && entity.hardwareBrand!.isNotEmpty) {
      brands.add(entity.hardwareBrand!);
    }
    if (entity.hardwareKeyway != null && entity.hardwareKeyway!.isNotEmpty) {
      keyways.add(entity.hardwareKeyway!);
    }

    final parts = await ref.read(jobPartsLocalDatasourceProvider).getPartsForJob(entity.id);
    for (final part in parts) {
      if (part.partName.isNotEmpty) partNames.add(part.partName);
    }
  }

  return CustomerHistorySuggestions(
    hardwareBrands: brands,
    hardwareKeyways: keyways,
    partNames: partNames,
  );
});
