import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arclock/features/inventory/data/models/pending_restock_wal.dart';
import 'package:arclock/core/storage/hive_service.dart';

/// Startup recovery hook for restock Write-Ahead Log.
///
/// Called once after Hive initialization. Replays any pending restock
/// transactions that were interrupted by a crash before their WAL entry
/// could be cleared.
///
/// Idempotent: each WAL carries the restockId which is checked against
/// the item's [appliedTransactionIds]. Already-applied restocks are skipped.
Future<void> reconcilePendingRestocks() async {
  final meta = Hive.box(HiveService.metaBox);
  final pendingKeys = meta.keys
      .where((k) => k.toString().startsWith('pending_restock:'))
      .toList();

  if (pendingKeys.isEmpty) return;

  debugPrint('[KS:RECOVERY] Found ${pendingKeys.length} pending restock WALs');

  for (final key in pendingKeys) {
    final raw = meta.get(key);
    if (raw == null) continue;

    try {
      final wal = PendingRestockWal.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      await _replayRestock(wal);
      await meta.delete(key);
      debugPrint('[KS:RECOVERY] Replayed and cleared restock WAL ${wal.restockId}');
    } catch (e) {
      debugPrint('[KS:RECOVERY] Failed to replay restock WAL $key: $e');
      // Don't delete — retry on next startup
    }
  }
}

Future<void> _replayRestock(PendingRestockWal wal) async {
  final invBox = Hive.box(HiveService.inventoryItemsBox);
  final raw = invBox.get(wal.itemId);
  if (raw == null) {
    debugPrint('[KS:RECOVERY] Restock item ${wal.itemId} not found — skipping');
    return;
  }

  final itemMap = Map<String, dynamic>.from(raw as Map);
  final appliedIds = itemMap['applied_transaction_ids'] != null
      ? List<String>.from(itemMap['applied_transaction_ids'] as List)
      : <String>[];

  if (appliedIds.contains(wal.restockId)) {
    debugPrint('[KS:RECOVERY] Restock ${wal.restockId} already applied to ${wal.itemId} — skipping');
    return;
  }

  // Recalculate weighted-average cost
  final currentQty = itemMap['quantity'] as int? ?? 0;
  final currentCost = itemMap['default_cost_price'] as int? ?? 0;
  final newQty = currentQty + wal.quantityDelta;
  final int newAvgCost;
  if (currentQty == 0 || currentCost == 0) {
    newAvgCost = wal.unitCost;
  } else {
    newAvgCost = ((currentQty * currentCost) + (wal.quantityDelta * wal.unitCost)) ~/ newQty;
  }

  itemMap['quantity'] = newQty;
  itemMap['default_cost_price'] = newAvgCost;
  appliedIds.add(wal.restockId);
  itemMap['applied_transaction_ids'] = appliedIds;
  itemMap['updated_at'] = DateTime.now().toIso8601String();

  await invBox.put(wal.itemId, itemMap);
  await invBox.flush();
  debugPrint('[KS:RECOVERY] Applied restock ${wal.restockId} to ${wal.itemId}: qty $currentQty→$newQty, cost $currentCost→$newAvgCost');
}
