import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/analytics/ks_analytics.dart';
import '../../../../core/analytics/analytics_constants.dart';
import '../../data/datasources/job_local_datasource.dart';
import '../../data/datasources/job_remote_datasource.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/repositories/job_repository.dart';
import '../../domain/usecases/get_jobs_usecase.dart';
import '../../domain/usecases/log_job_usecase.dart';
import '../../domain/usecases/sync_offline_jobs_usecase.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';

final jobLocalDatasourceProvider = Provider<JobLocalDatasource>((ref) => JobLocalDatasource());
final jobRemoteDatasourceProvider = Provider<JobRemoteDatasource>((ref) => JobRemoteDatasource(ref.watch(supabaseClientProvider)));
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());
final jobRepositoryProvider = Provider<JobRepository>((ref) => JobRepositoryImpl(ref.watch(jobRemoteDatasourceProvider), ref.watch(jobLocalDatasourceProvider), ref.watch(connectivityServiceProvider), ref.watch(supabaseClientProvider)));
final getJobsUsecaseProvider = Provider<GetJobsUsecase>((ref) => GetJobsUsecase(ref.watch(jobRepositoryProvider)));
final logJobUsecaseProvider = Provider<LogJobUsecase>((ref) => LogJobUsecase(ref.watch(jobRepositoryProvider)));
final syncOfflineJobsUsecaseProvider = Provider<SyncOfflineJobsUsecase>((ref) => SyncOfflineJobsUsecase(ref.watch(jobRepositoryProvider)));

class JobListState {
  final List<JobEntity> jobs;
  final bool isLoading;
  final String? errorMessage;
  const JobListState({this.jobs = const [], this.isLoading = false, this.errorMessage});
  JobListState copyWith({List<JobEntity>? jobs, bool? isLoading, String? errorMessage, bool clearError = false}) {
    return JobListState(jobs: jobs ?? this.jobs, isLoading: isLoading ?? this.isLoading, errorMessage: clearError ? null : (errorMessage ?? this.errorMessage));
  }
  int get totalJobs => jobs.length;
  double get thisMonthEarnings {
    final now = DateTime.now();
    return jobs.where((j) => j.jobDate.year == now.year && j.jobDate.month == now.month).fold(0.0, (sum, j) => sum + (j.amountCharged ?? 0.0));
  }
}

class JobListNotifier extends StateNotifier<JobListState> {
  final GetJobsUsecase _getJobs;
  final SyncOfflineJobsUsecase _syncOffline;
  JobListNotifier(this._getJobs, this._syncOffline) : super(const JobListState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final jobs = await _getJobs(const GetJobsParams());
      state = state.copyWith(jobs: jobs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load jobs.');
    }
  }
  Future<void> refresh() async { await _syncOffline(); await load(); }
  void addJob(JobEntity job) { state = state.copyWith(jobs: [job, ...state.jobs]); }
}

final jobListProvider = StateNotifierProvider<JobListNotifier, JobListState>((ref) => JobListNotifier(ref.watch(getJobsUsecaseProvider), ref.watch(syncOfflineJobsUsecaseProvider)));

class LogJobState {
  final bool isLoading;
  final String? errorMessage;
  final bool saved;
  const LogJobState({this.isLoading = false, this.errorMessage, this.saved = false});
  LogJobState copyWith({bool? isLoading, String? errorMessage, bool? saved, bool clearError = false}) {
    return LogJobState(isLoading: isLoading ?? this.isLoading, errorMessage: clearError ? null : (errorMessage ?? this.errorMessage), saved: saved ?? this.saved);
  }
}

class LogJobNotifier extends StateNotifier<LogJobState> {
  final LogJobUsecase _logJob;
  final SupabaseClient _supabase;
  LogJobNotifier(this._logJob, this._supabase) : super(const LogJobState());
  Future<JobEntity?> save({required ServiceType serviceType, required String customerId, required DateTime jobDate, String? location, double? latitude, double? longitude, String? notes, double? amountCharged}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final job = await _logJob(LogJobParams(userId: userId, customerId: customerId, serviceType: serviceType, jobDate: jobDate, location: location, latitude: latitude, longitude: longitude, notes: notes, amountCharged: amountCharged));
      state = state.copyWith(isLoading: false, saved: true);
      KsAnalytics.log(AnalyticsEvents.jobLogged, properties: {
        'service_type': serviceType.name,
        'has_amount': amountCharged != null,
      });
      return job;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
  void reset() => state = const LogJobState();
}

final logJobProvider = StateNotifierProvider<LogJobNotifier, LogJobState>((ref) => LogJobNotifier(ref.watch(logJobUsecaseProvider), ref.watch(supabaseClientProvider)));
