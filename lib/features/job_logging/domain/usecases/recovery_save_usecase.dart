import 'package:uuid/uuid.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/job_entity.dart';
import '../entities/job_part_entity.dart';
import '../entities/job_service_entity.dart';
import '../entities/job_hardware_entity.dart';
import '../entities/job_expense_entity.dart';
import '../repositories/job_repository.dart';
import '../../../inventory/domain/entities/inventory_item_entity.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';

/// Parameters for [RecoverySaveUsecase].
///
/// Carries the full current state of a job's sub-entities so the use case can
/// diff against what's already persisted in Hive.
class RecoverySaveParams {
  final String jobId;
  final String userId;
  final List<JobPartEntity> parts;
  final List<JobServiceEntity> services;
  final List<JobHardwareEntity> hardware;
  final List<JobExpenseEntity> expenses;

  const RecoverySaveParams({
    required this.jobId,
    required this.userId,
    this.parts = const [],
    this.services = const [],
    this.hardware = const [],
    this.expenses = const [],
  });
}

/// Recovers an orphaned job (subEntitiesSaved == false) by diffing the caller's
/// payload against existing Hive records at the item level.
///
/// **Logic per child type:**
/// 1. Load existing records from Hive, index by UUID.
/// 2. Incoming items whose UUID already exists → update in-place (no COGS).
/// 3. Incoming items with fresh UUIDs → save + deduct COGS if auto-cogs.
/// 4. Missing UUIDs (orphans from a prior partial save) are deleted.
///
/// **Terminal action:** flips `subEntitiesSaved → true`.
///
/// **Does NOT touch:** syncStatus, syncErrorMessage, creation timestamps.
class RecoverySaveUsecase implements UseCase<void, RecoverySaveParams> {
  final JobRepository _jobRepo;
  final InventoryRepository _invRepo;

  RecoverySaveUsecase(this._jobRepo, this._invRepo);

  @override
  Future<void> call(RecoverySaveParams params) async {
    // ── 1. Load existing Hive state for diffing ──
    final existingParts = await _jobRepo.getPartsForJob(params.jobId);
    final existingServices = await _jobRepo.getServicesForJob(params.jobId);
    final existingHardware = await _jobRepo.getHardwareForJob(params.jobId);
    final existingExpenses = await _jobRepo.getExpensesForJob(params.jobId);

    final existingPartIds = existingParts.map((e) => e.id).toSet();
    final existingServiceIds = existingServices.map((e) => e.id).toSet();
    final existingHardwareIds = existingHardware.map((e) => e.id).toSet();
    final existingExpenseIds = existingExpenses.map((e) => e.id).toSet();

    // ── 2. Identify net-new auto-cogs items ──
    final allInv = await _invRepo.getItems(params.userId);

    // ── 3. Compute COGS adjustments for net-new parts ──
    final netNewParts =
        params.parts.where((p) => !existingPartIds.contains(p.id)).toList();
    for (final part in netNewParts) {
      if (part.inventoryItemId == null) continue;
      final invItem = allInv.where(
        (i) => i.id == part.inventoryItemId && i.isAutoCogs,
      ).firstOrNull;
      if (invItem == null) continue;
      await _invRepo.adjustStock(
        invItem.id,
        params.userId,
        -(part.quantity ?? 1),
        'job_use',
        reason: 'Recovery-COGS: ${part.partName} used in job ${params.jobId.substring(0, 8)}',
        referenceType: 'job',
        referenceId: params.jobId,
      );
    }

    // ── 4. Save ALL children (save-first-then-delete handles orphans) ──
    if (params.parts.isNotEmpty || existingPartIds.isNotEmpty) {
      await _jobRepo.saveParts(params.jobId, params.parts);
    }
    if (params.services.isNotEmpty || existingServiceIds.isNotEmpty) {
      await _jobRepo.saveServices(params.jobId, params.services);
    }
    if (params.hardware.isNotEmpty || existingHardwareIds.isNotEmpty) {
      await _jobRepo.saveHardwareItems(params.jobId, params.hardware);
    }
    if (params.expenses.isNotEmpty || existingExpenseIds.isNotEmpty) {
      await _jobRepo.saveExpenses(params.jobId, params.expenses);
    }

    // ── 5. Mark recovery complete ──
    await _jobRepo.setSubEntitiesSaved(params.jobId, true);
  }
}
