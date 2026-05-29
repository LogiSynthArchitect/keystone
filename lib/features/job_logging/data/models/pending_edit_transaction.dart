/// Cross-box Write-Ahead Log entry for atomic edit recovery.
///
/// Written to the `_meta` Hive box BEFORE any mutations in a multi-box edit
/// (child entity replacement + inventory COGS adjustment).
///
/// On crash recovery, the startup hook replays pending transactions by:
/// 1. Deleting orphan keys (idempotent — deleteAll of non-existent keys is no-op)
/// 2. Applying inventory deltas ONLY IF the transaction ID hasn't already been
///    recorded in the item's `appliedTransactionIds` (preventing double-refund)
///
/// The transaction is deleted AFTER all mutations complete successfully,
/// so a missing transaction entry means "fully applied or never started."
class PendingEditTransaction {
  final String id;
  final String jobId;
  final Map<String, List<String>> deletions;
  final List<InventoryCogsAdjustment> cogsAdjustments;
  final DateTime createdAt;

  const PendingEditTransaction({
    required this.id,
    required this.jobId,
    this.deletions = const {},
    this.cogsAdjustments = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'job_id': jobId,
    'deletions': deletions.map((k, v) => MapEntry(k, v)),
    'cogs_adjustments': cogsAdjustments.map((a) => a.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
  };

  factory PendingEditTransaction.fromJson(Map<String, dynamic> json) =>
    PendingEditTransaction(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      deletions: (json['deletions'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      ) ?? {},
      cogsAdjustments: (json['cogs_adjustments'] as List<dynamic>?)
        ?.map((a) => InventoryCogsAdjustment.fromJson(a as Map<String, dynamic>))
        .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
}

/// A single inventory COGS adjustment bound to a transaction.
///
/// Uses delta (relative change) rather than absolute stock target so that
/// concurrent background syncs that modify inventory between the crash and
/// the recovery hook invocation are preserved — the delta is only applied
/// if the [transactionId] is not already in the item's [appliedTransactionIds].
class InventoryCogsAdjustment {
  final String transactionId;
  final String itemId;
  final int delta;
  final String reason;
  final String referenceType;
  final String referenceId;

  const InventoryCogsAdjustment({
    required this.transactionId,
    required this.itemId,
    required this.delta,
    required this.reason,
    required this.referenceType,
    required this.referenceId,
  });

  Map<String, dynamic> toJson() => {
    'transaction_id': transactionId,
    'item_id': itemId,
    'delta': delta,
    'reason': reason,
    'reference_type': referenceType,
    'reference_id': referenceId,
  };

  factory InventoryCogsAdjustment.fromJson(Map<String, dynamic> json) =>
    InventoryCogsAdjustment(
      transactionId: json['transaction_id'] as String,
      itemId: json['item_id'] as String,
      delta: json['delta'] as int,
      reason: json['reason'] as String,
      referenceType: json['reference_type'] as String,
      referenceId: json['reference_id'] as String,
    );
}
