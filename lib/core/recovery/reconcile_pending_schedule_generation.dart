import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/core/storage/hive_service.dart';

/// Cross-box Write-Ahead Log entry for recurring schedule job generation.
///
/// Written to the `_meta` Hive box BEFORE any mutations in generateDueJobs().
/// Records the batch_id and target schedule IDs so crash recovery can
/// determine whether jobs were written but schedules weren't advanced.
///
/// Recovery logic:
/// 1. If NO jobs exist with this [batchId] → crash happened before payload
///    write. Safe to discard — user re-triggers generation.
/// 2. If jobs exist but schedule [nextDueDate] still matches the job's
///    [jobDate] → crash happened between payload write and schedule advance.
///    Recovery advances the schedule.
/// 3. If jobs exist AND schedule [nextDueDate] already changed → schedule
///    was already advanced. No action needed.
class PendingScheduleGenerationWal {
  final String batchId;
  final List<String> targetScheduleIds;
  final String state;
  final DateTime createdAt;

  const PendingScheduleGenerationWal({
    required this.batchId,
    required this.targetScheduleIds,
    this.state = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'batch_id': batchId,
    'target_schedule_ids': targetScheduleIds,
    'state': state,
    'created_at': createdAt.toIso8601String(),
  };

  factory PendingScheduleGenerationWal.fromJson(Map<String, dynamic> json) =>
    PendingScheduleGenerationWal(
      batchId: json['batch_id'] as String,
      targetScheduleIds: List<String>.from(json['target_schedule_ids'] as List),
      state: json['state'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
}

/// Startup recovery hook for interrupted schedule job generation.
///
/// Called once after Hive initialization. Replays any pending schedule
/// generation WALs that were interrupted by a crash before the WAL entry
/// could be cleared.
///
/// Idempotent: checks [generationBatchId] on stored jobs and compares
/// schedule [nextDueDate] against job [jobDate] before advancing.
Future<void> reconcilePendingScheduleGeneration() async {
  final meta = Hive.box(HiveService.metaBox);
  final pendingKeys = meta.keys
      .where((k) => k.toString().startsWith('pending_schedule_gen:'))
      .toList();

  if (pendingKeys.isEmpty) return;

  debugPrint('[KS:RECOVERY] Found ${pendingKeys.length} pending schedule generation WALs');

  for (final key in pendingKeys) {
    final raw = meta.get(key);
    if (raw == null) continue;

    try {
      final wal = PendingScheduleGenerationWal.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      await _replayScheduleGeneration(wal);
      await meta.delete(key);
      debugPrint('[KS:RECOVERY] Replayed and cleared schedule gen WAL ${wal.batchId}');
    } catch (e) {
      debugPrint('[KS:RECOVERY] Failed to replay schedule gen WAL $key: $e');
      // Don't delete — retry on next startup
    }
  }
}

Future<void> _replayScheduleGeneration(PendingScheduleGenerationWal wal) async {
  final jobsBox = Hive.box(HiveService.jobsBox);
  final schedulesBox = Hive.box(HiveService.recurringSchedulesBox);

  // Collect all jobs from this generation batch
  final matchingJobs = jobsBox.values
      .map((e) => Map<String, dynamic>.from(e as Map))
      .where((j) => j['generation_batch_id'] == wal.batchId)
      .toList();

  if (matchingJobs.isEmpty) {
    debugPrint('[KS:RECOVERY] No jobs found for batch ${wal.batchId} — generation never completed. Discarding.');
    return;
  }

  debugPrint('[KS:RECOVERY] Found ${matchingJobs.length} jobs for batch ${wal.batchId} — advancing schedules');

  for (final scheduleId in wal.targetScheduleIds) {
    final raw = schedulesBox.get(scheduleId);
    if (raw == null) {
      debugPrint('[KS:RECOVERY] Schedule $scheduleId not found (deleted) — skipping');
      continue;
    }

    final scheduleMap = Map<String, dynamic>.from(raw as Map);
    final currentNextDueDate = DateTime.tryParse(
      (scheduleMap['next_due_date'] as String?) ?? '',
    );
    if (currentNextDueDate == null) {
      debugPrint('[KS:RECOVERY] Schedule $scheduleId has no valid next_due_date — skipping');
      continue;
    }

    // Find job(s) generated from this schedule in this batch
    final batchJobsForSchedule = matchingJobs
        .where((j) => j['generated_from_schedule_id'] == scheduleId)
        .toList();
    if (batchJobsForSchedule.isEmpty) continue;

    // Use the first job's jobDate as the original due date
    final originalDueDateStr = batchJobsForSchedule.first['job_date'] as String?;
    final originalDueDate = originalDueDateStr != null
        ? DateTime.tryParse(originalDueDateStr)
        : null;
    if (originalDueDate == null) continue;

    // If nextDueDate has already moved past the original due date,
    // the schedule was already advanced — idempotent skip
    if (!_isSameDate(currentNextDueDate, originalDueDate)) {
      debugPrint('[KS:RECOVERY] Schedule $scheduleId already advanced (nextDueDate $currentNextDueDate ≠ jobDate $originalDueDate) — skipping');
      continue;
    }

    // Advance the schedule
    final intervalType = scheduleMap['interval_type'] as String? ?? 'monthly';
    final advanced = _advanceNextDueDate(currentNextDueDate, intervalType);
    scheduleMap['next_due_date'] = advanced.toIso8601String().split('T').first;
    scheduleMap['updated_at'] = DateTime.now().toIso8601String();

    await schedulesBox.put(scheduleId, scheduleMap);
    debugPrint('[KS:RECOVERY] Advanced schedule $scheduleId: $currentNextDueDate → $advanced');
  }

  await schedulesBox.flush();
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _advanceNextDueDate(DateTime next, String intervalType) {
  switch (intervalType) {
    case 'weekly':    return next.add(const Duration(days: 7));
    case 'monthly':   return DateTime(next.year, next.month + 1, next.day);
    case 'quarterly': return DateTime(next.year, next.month + 3, next.day);
    case 'yearly':    return DateTime(next.year + 1, next.month, next.day);
    default:          return next.add(const Duration(days: 30));
  }
}
