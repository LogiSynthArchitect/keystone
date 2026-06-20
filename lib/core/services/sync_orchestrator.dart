import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/service_types/domain/repositories/service_type_repository.dart';
import '../../features/knowledge_base/domain/repositories/knowledge_note_repository.dart';
import '../../features/customer_history/domain/repositories/customer_repository.dart';
import '../../features/job_logging/domain/repositories/job_repository.dart';
import '../network/connectivity_service.dart';
import 'sync/sync_worker.dart';

/// Result of a single sync phase.
class SyncPhaseResult {
  final String name;
  final bool success;
  final String? error;
  const SyncPhaseResult(this.name, this.success, {this.error});
}

/// Centralized sync daemon with DAG phase ordering.
///
/// Phase order: SyncWorker (outbox queue drain) → Service Types → Inventory →
/// Customers → Jobs → Notes
/// Each phase: PUSH pending → PULL diff merge → advance to next phase
class SyncOrchestrator {
  final SyncWorker? _syncWorker;
  final InventoryRepository _inventoryRepo;
  final ServiceTypeRepository _serviceTypeRepo;
  final KnowledgeNoteRepository _notesRepo;
  final CustomerRepository _customersRepo;
  final JobRepository _jobsRepo;
  final ConnectivityService _connectivity;
  final String _userId;

  SyncOrchestrator({
    SyncWorker? syncWorker,
    required InventoryRepository inventoryRepo,
    required ServiceTypeRepository serviceTypeRepo,
    required KnowledgeNoteRepository notesRepo,
    required CustomerRepository customersRepo,
    required JobRepository jobsRepo,
    required ConnectivityService connectivity,
    required String userId,
  })  : _syncWorker = syncWorker,
        _inventoryRepo = inventoryRepo,
        _serviceTypeRepo = serviceTypeRepo,
        _notesRepo = notesRepo,
        _customersRepo = customersRepo,
        _jobsRepo = jobsRepo,
        _connectivity = connectivity,
        _userId = userId;

  /// Run all sync phases in DAG order. Returns results for each phase.
  /// A failing phase does not block subsequent phases.
  Future<List<SyncPhaseResult>> runFullSync() async {
    if (!await _connectivity.isConnected) return [];

    final results = <SyncPhaseResult>[];

    // Phase 0: Drain the mutation outbox queue
    results.add(await _runPhase('SyncWorker (outbox queue)', () async {
      final processed = await _syncWorker?.processQueue() ?? 0;
      if (processed > 0) {
        debugPrint('[KS:SYNC] SyncWorker drained $processed tasks from queue');
      }
    }));

    // Phase 1: Service Types — PULL diff-merge
    results.add(await _runPhase('Service Types', () async {
      await _serviceTypeRepo.syncServiceTypes();
    }));

    // Phase 2: Inventory — PUSH pending → PULL diff-merge
    results.add(await _runPhase('Inventory', () async {
      await _inventoryRepo.syncItems(_userId);
    }));

    // Phase 3: Customers — PUSH pending
    results.add(await _runPhase('Customers', () async {
      await _customersRepo.syncPendingCustomers();
    }));

    // Phase 4: Jobs — PUSH pending
    results.add(await _runPhase('Jobs', () async {
      await _jobsRepo.syncPendingJobs();
    }));

    // Phase 5: Notes — PUSH pending via upsert
    results.add(await _runPhase('Notes', () async {
      await _notesRepo.syncPendingNotes();
    }));

    return results;
  }

  Future<SyncPhaseResult> _runPhase(String name, Future<void> Function() fn) async {
    try {
      debugPrint('[KS:SYNC] Starting phase: $name');
      await fn().timeout(const Duration(seconds: 30));
      debugPrint('[KS:SYNC] Completed phase: $name');
      return SyncPhaseResult(name, true);
    } on TimeoutException {
      debugPrint('[KS:SYNC] Timed out phase: $name');
      return SyncPhaseResult(name, false, error: 'Timed out after 30s');
    } catch (e) {
      debugPrint('[KS:SYNC] Failed phase: $name — $e');
      return SyncPhaseResult(name, false, error: e.toString());
    }
  }
}
