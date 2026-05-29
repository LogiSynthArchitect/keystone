/// Write-Ahead Log entry for restock transaction recovery.
///
/// Written to the `_meta` Hive box BEFORE mutating item stock/cost.
/// On crash recovery, [reconcilePendingRestocks] replays pending WALs
/// that were interrupted before their entry could be cleared.
///
/// Safe to replay — the restock's transactionId is checked against
/// the item's [appliedTransactionIds] to prevent double-application.
class PendingRestockWal {
  final String restockId;
  final String itemId;
  final int quantityDelta;
  final int unitCost;
  final int previousCost;
  final int previousQty;
  final DateTime createdAt;

  const PendingRestockWal({
    required this.restockId,
    required this.itemId,
    required this.quantityDelta,
    required this.unitCost,
    required this.previousCost,
    required this.previousQty,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'restock_id': restockId,
    'item_id': itemId,
    'quantity_delta': quantityDelta,
    'unit_cost': unitCost,
    'previous_cost': previousCost,
    'previous_qty': previousQty,
    'created_at': createdAt.toIso8601String(),
  };

  factory PendingRestockWal.fromJson(Map<String, dynamic> json) =>
    PendingRestockWal(
      restockId: json['restock_id'] as String,
      itemId: json['item_id'] as String,
      quantityDelta: json['quantity_delta'] as int,
      unitCost: json['unit_cost'] as int,
      previousCost: json['previous_cost'] as int,
      previousQty: json['previous_qty'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
}
