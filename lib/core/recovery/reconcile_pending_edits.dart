import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arclock/features/job_logging/data/models/pending_edit_transaction.dart';
import 'package:arclock/core/storage/hive_service.dart';

/// Startup recovery hook for cross-box Write-Ahead Log.
///
/// Called once after Hive initialization. Replays any pending edit
/// transactions that were interrupted by a crash before their WAL
/// entry could be cleared.
///
/// Safe to run multiple times — all operations are idempotent:
/// - deleteAll of non-existent keys is a no-op
/// - adjustStock skips if transactionId is already in appliedTransactionIds
Future<void> reconcilePendingEdits() async {
  final meta = Hive.box(HiveService.metaBox);
  final pendingKeys = meta.keys
      .where((k) => k.toString().startsWith('pending_edit:'))
      .toList();

  if (pendingKeys.isEmpty) return;

  debugPrint('[KS:RECOVERY] Found ${pendingKeys.length} pending edit transactions');

  for (final key in pendingKeys) {
    final raw = meta.get(key);
    if (raw == null) continue;

    try {
      final tx = PendingEditTransaction.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      await _replayTransaction(tx);
      await meta.delete(key);
      debugPrint('[KS:RECOVERY] Replayed and cleared transaction ${tx.id}');
    } catch (e) {
      debugPrint('[KS:RECOVERY] Failed to replay $key: $e');
      // Don't delete — retry on next startup
    }
  }
}

Future<void> _replayTransaction(PendingEditTransaction tx) async {
  // Phase 1: Delete orphan keys (idempotent)
  for (final entry in tx.deletions.entries) {
    final box = _childBoxForType(entry.key);
    if (box == null) {
      debugPrint('[KS:RECOVERY] Unknown child type: ${entry.key}');
      continue;
    }
    final keysToDelete = entry.value.where((k) => box.containsKey(k)).toList();
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
      await box.flush();
      debugPrint('[KS:RECOVERY] Deleted ${keysToDelete.length} orphans from ${entry.key}');
    }
  }

  // Phase 2: Apply inventory COGS adjustments (idempotent via transactionId)
  final invBox = Hive.box(HiveService.inventoryItemsBox);
  for (final adj in tx.cogsAdjustments) {
    final raw = invBox.get(adj.itemId);
    if (raw == null) {
      debugPrint('[KS:RECOVERY] Inventory item ${adj.itemId} not found — skipping');
      continue;
    }

    final itemMap = Map<String, dynamic>.from(raw as Map);
    final appliedIds = itemMap['applied_transaction_ids'] != null
        ? List<String>.from(itemMap['applied_transaction_ids'] as List)
        : <String>[];

    if (appliedIds.contains(adj.transactionId)) {
      debugPrint('[KS:RECOVERY] Transaction ${adj.transactionId} already applied to ${adj.itemId} — skipping');
      continue;
    }

    // Apply delta
    final currentQty = itemMap['quantity'] as int? ?? 0;
    final newQty = (currentQty + adj.delta).clamp(0, 999999);
    itemMap['quantity'] = newQty;
    appliedIds.add(adj.transactionId);
    itemMap['applied_transaction_ids'] = appliedIds;
    itemMap['updated_at'] = DateTime.now().toIso8601String();

    await invBox.put(adj.itemId, itemMap);
    debugPrint('[KS:RECOVERY] Applied COGS delta ${adj.delta} to ${adj.itemId}: $currentQty → $newQty');
  }

  await invBox.flush();
}

Box? _childBoxForType(String type) {
  switch (type) {
    case 'parts':    return Hive.box(HiveService.jobPartsBox);
    case 'services': return Hive.box(HiveService.jobServicesBox);
    case 'hardware': return Hive.box(HiveService.jobHardwareBox);
    case 'expenses': return Hive.box(HiveService.jobExpensesBox);
    default:         return null;
  }
}
