import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/analytics/data/repositories/rollup_repository.dart';

/// Writes an invalidation WAL entry for a single date.
///
/// Called from job mutation points (save, edit, archive, delete) after
/// the Hive write succeeds. The WAL is stored in the `_meta` box under
/// a prefixed key so the startup recovery hook can replay it.
///
/// The WAL is NOT deleted by the mutation caller — it is consumed by
/// [reconcileAnalyticsInvalidations] which runs at startup and before
/// each analytics computation.
Future<void> markAnalyticsDirty(String dateKey, {String reason = 'unknown'}) async {
  final meta = Hive.box(HiveService.metaBox);
  final key = 'analytics_dirty:$dateKey';
  // Only write if not already dirty — no need to duplicate
  if (meta.containsKey(key)) return;
  await meta.put(key, {
    'date_key': dateKey,
    'reason': reason,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  debugPrint('[KS:ANALYTICS] Marked $dateKey dirty ($reason)');
}

/// Writes invalidation WAL entries for a batch of dates.
///
/// Used when a single operation affects multiple dates (e.g., job date change).
Future<void> markAnalyticsDirtyBatch(Iterable<String> dateKeys, {String reason = 'batch'}) async {
  for (final dk in dateKeys) {
    await markAnalyticsDirty(dk, reason: reason);
  }
}

/// Current format version for analytics rollups.
///
/// Bump when the [DailyRollup] model changes field types or semantics so
/// stale rollups from a previous build are automatically re-seeded.
const int analyticsRollupVersion = 2;

/// Startup recovery hook for analytics rollup invalidation.
///
/// Called once after Hive initialization AND before any analytics
/// computation. Reads pending invalidation WALs from the `_meta` box,
/// recomputes the affected dates' rollups, then clears the WAL entries.
///
/// Also runs the initial seed if the rollups box is empty (first launch
/// after update or fresh install).
///
/// Idempotent: each date is recomputed independently. If recomputation
/// fails for one date, its WAL is preserved for retry on next startup.
Future<void> reconcileAnalyticsInvalidations() async {
  final meta = Hive.box(HiveService.metaBox);
  final repo = RollupRepository();

  // ── Rollup format version check ──
  // If the stored format version doesn't match, clear stale rollups and
  // re-seed from source data (handles int→double type fixes, new fields, etc.)
  final storedRollupVer = meta.get('analytics_rollup_version') as int? ?? 0;
  if (storedRollupVer < analyticsRollupVersion) {
    debugPrint('[KS:ROLLUP] Format version $storedRollupVer → $analyticsRollupVersion, re-seeding');
    final rollupsBox = Hive.box(HiveService.analyticsDailyRollupsBox);
    await rollupsBox.clear();
    _clearAllDirtyWals(meta);
  }

  // ── Initial seed? ──
  if (repo.isEmpty) {
    await repo.seedAll();
    // Seed writes rollups for all dates — no WAL processing needed
    // Clean up any stale WALs that might exist from before seed was implemented
    _clearAllDirtyWals(meta);
    await meta.put('analytics_rollup_version', analyticsRollupVersion);
    return;
  }

  // ── Process pending invalidation WALs ──
  final pendingKeys = meta.keys
      .where((k) => k.toString().startsWith('analytics_dirty:'))
      .toList();

  if (pendingKeys.isEmpty) return;

  debugPrint('[KS:RECOVERY] Found ${pendingKeys.length} pending analytics invalidation WALs');

  final dateKeys = <String>[];
  for (final key in pendingKeys) {
    final raw = meta.get(key);
    if (raw is! Map) continue;
    final dk = raw['date_key'] as String?;
    if (dk == null || dk.isEmpty) continue;
    dateKeys.add(dk);
  }

  // Deduplicate: multiple WALs may reference the same date
  final uniqueDates = dateKeys.toSet();

  int successCount = 0;
  int failCount = 0;

  for (final dk in uniqueDates) {
    try {
      await repo.recomputeDate(dk);
      // Clear all WALs for this date
      final toRemove = pendingKeys.where((k) {
        final raw = meta.get(k);
        return raw is Map && raw['date_key'] == dk;
      }).toList();
      for (final k in toRemove) {
        await meta.delete(k);
      }
      successCount++;
    } catch (e) {
      debugPrint('[KS:RECOVERY] Failed to recompute analytics for $dk: $e');
      failCount++;
    }
  }

  debugPrint('[KS:RECOVERY] Analytics invalidation: $successCount recomputed, $failCount failed');
  await meta.put('analytics_rollup_version', analyticsRollupVersion);
  await meta.flush();
}

/// Clear all analytics dirty WALs (used after full seed).
void _clearAllDirtyWals(Box meta) {
  final keys = meta.keys
      .where((k) => k.toString().startsWith('analytics_dirty:'))
      .toList();
  for (final k in keys) {
    meta.delete(k);
  }
  debugPrint('[KS:RECOVERY] Cleared ${keys.length} stale analytics WALs after seed');
}
