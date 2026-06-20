import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync/sync_worker.dart';
import '../services/sync_orchestrator.dart';
import 'connectivity_provider.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';
import 'sync_queue_provider.dart';
import '../../features/customer_history/data/datasources/customer_remote_datasource.dart';
import '../../features/customer_history/presentation/providers/customer_providers.dart';
import '../../features/job_logging/data/datasources/job_remote_datasource.dart';
import '../../features/job_logging/presentation/providers/job_providers.dart';
import '../../features/inventory/presentation/providers/inventory_providers.dart';
import '../../features/service_types/presentation/providers/service_type_provider.dart';
import '../../features/knowledge_base/presentation/providers/notes_providers.dart';

/// Provider for SyncWorker — drains the mutation queue to Supabase.
final syncWorkerProvider = Provider<SyncWorker>((ref) {
  return SyncWorker(
    queue: ref.watch(syncQueueServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    customerRemote: ref.watch(customerRemoteDatasourceProvider),
    jobRemote: ref.watch(jobRemoteDatasourceProvider),
  );
});

final customerRemoteDatasourceProvider = Provider<CustomerRemoteDatasource>((ref) {
  return CustomerRemoteDatasource(ref.watch(supabaseClientProvider));
});

final jobRemoteDatasourceProvider = Provider<JobRemoteDatasource>((ref) {
  return JobRemoteDatasource(ref.watch(supabaseClientProvider));
});

/// Current authenticated user ID (empty string if not logged in).
final currentUserIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  final session = authState.valueOrNull?.session;
  return session?.user.id ?? '';
});

/// Provider for SyncOrchestrator — runs the full sync DAG.
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SyncOrchestrator(
    syncWorker: ref.watch(syncWorkerProvider),
    inventoryRepo: ref.watch(inventoryRepositoryProvider),
    serviceTypeRepo: ref.watch(serviceTypeRepositoryProvider),
    notesRepo: ref.watch(knowledgeNoteRepositoryProvider),
    customersRepo: ref.watch(customerRepositoryProvider),
    jobsRepo: ref.watch(jobRepositoryProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    userId: userId,
  );
});
