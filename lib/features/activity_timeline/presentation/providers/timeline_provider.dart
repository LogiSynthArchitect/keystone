import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/job_logging/data/models/job_audit_entry_model.dart';
import 'package:keystone/features/job_logging/domain/entities/job_audit_entry_entity.dart';
import 'package:keystone/features/job_logging/data/models/job_model.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';

class TimelineEvent {
  final String id;
  final String jobId;
  final String description;
  final DateTime timestamp;
  final TimelineEventType type;
  final Map<String, dynamic>? details;

  const TimelineEvent({
    required this.id,
    required this.jobId,
    required this.description,
    required this.timestamp,
    required this.type,
    this.details,
  });
}

enum TimelineEventType {
  jobCreated,
  jobEdited,
  statusChanged,
  paymentChanged,
  archived,
  correctionRequested,
  followUpSent,
}

extension TimelineEventTypeLabel on TimelineEventType {
  String get label {
    switch (this) {
      case TimelineEventType.jobCreated:           return 'JOB LOGGED';
      case TimelineEventType.jobEdited:            return 'JOB EDITED';
      case TimelineEventType.statusChanged:        return 'STATUS CHANGED';
      case TimelineEventType.paymentChanged:       return 'PAYMENT UPDATED';
      case TimelineEventType.archived:             return 'JOB ARCHIVED';
      case TimelineEventType.correctionRequested:  return 'CORRECTION REQUESTED';
      case TimelineEventType.followUpSent:         return 'FOLLOW-UP SENT';
    }
  }
}

class TimelineState {
  final List<TimelineEvent> events;
  final bool isLoading;
  final String? errorMessage;
  final int loadedCount;
  final int totalCount;

  const TimelineState({
    this.events = const [],
    this.isLoading = false,
    this.errorMessage,
    this.loadedCount = 0,
    this.totalCount = 0,
  });
}

class TimelineNotifier extends StateNotifier<TimelineState> {
  TimelineNotifier() : super(const TimelineState()) {
    load();
  }

  /// Cached job lookup, populated by [load] and reused by [loadMore].
  Map<String, JobEntity>? _cachedJobMap;

  Map<String, JobEntity> _buildJobMap() {
    final map = <String, JobEntity>{};
    for (final j in HiveService.jobs.values) {
      try {
        final job = JobModel.fromJson(Map<String, dynamic>.from(j)).toEntity();
        map[job.id] = job;
      } catch (err) {
        debugPrint('[KS:TIMELINE] Skipping bad job entry: $err');
      }
    }
    return map;
  }

  Future<void> load() async {
    state = const TimelineState(isLoading: true);
    try {
      // Read all audit entries from Hive — skip bad entries instead of crashing
      final allEntries = <JobAuditEntryEntity>[];
      for (final e in HiveService.jobAuditLog.values) {
        try {
          allEntries.add(
            JobAuditEntryModel.fromJson(Map<String, dynamic>.from(e)).toEntity(),
          );
        } catch (err) {
          debugPrint('[KS:TIMELINE] Skipping bad audit entry: $err');
        }
      }

      // Build job lookup for descriptions — skip bad entries, cache for loadMore
      _cachedJobMap = _buildJobMap();
      final jobMap = _cachedJobMap!;

      // Sort all by time, newest first
      allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final total = allEntries.length;
      final initialCount = total > 50 ? 50 : total;

      // Convert each entry — skip conversions that fail
      final events = <TimelineEvent>[];
      for (final entry in allEntries.take(initialCount)) {
        try {
          events.add(_toEvent(entry, jobMap));
        } catch (err) {
          debugPrint('[KS:TIMELINE] Skipping bad event conversion: $err');
        }
      }

      state = TimelineState(events: events, loadedCount: initialCount, totalCount: total);
    } catch (e) {
      debugPrint('[KS:TIMELINE] Load failed: $e');
      state = const TimelineState(errorMessage: 'Could not load activity.');
    }
  }

  Future<void> loadMore() async {
    if (state.loadedCount >= state.totalCount) return;
    try {
      final allEntries = <JobAuditEntryEntity>[];
      for (final e in HiveService.jobAuditLog.values) {
        try {
          allEntries.add(
            JobAuditEntryModel.fromJson(Map<String, dynamic>.from(e)).toEntity(),
          );
        } catch (err) {
          debugPrint('[KS:TIMELINE] Skipping bad audit entry: $err');
        }
      }

      // Reuse cached job map from initial load instead of rebuilding it
      final jobMap = _cachedJobMap ?? _buildJobMap();

      allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final newCount = state.loadedCount + 50 > state.totalCount
          ? state.totalCount
          : state.loadedCount + 50;

      // Convert each entry — skip conversions that fail
      final events = <TimelineEvent>[];
      for (final entry in allEntries.take(newCount)) {
        try {
          events.add(_toEvent(entry, jobMap));
        } catch (err) {
          debugPrint('[KS:TIMELINE] Skipping bad event conversion: $err');
        }
      }

      state = TimelineState(events: events, loadedCount: newCount, totalCount: state.totalCount);
    } catch (e) {
      debugPrint('[KS:TIMELINE] loadMore failed: $e');
    }
  }

  TimelineEvent _toEvent(JobAuditEntryEntity entry, Map<String, JobEntity> jobMap) {
    final job = jobMap[entry.jobId];
    final jobLabel = job?.serviceType ?? '(deleted job)';
    final type = _parseType(entry.action, entry.newValues);
    final description = _buildDescription(type, jobLabel, entry);

    return TimelineEvent(
      id: entry.id,
      jobId: entry.jobId,
      description: description,
      timestamp: entry.createdAt,
      type: type,
      details: entry.newValues,
    );
  }

  TimelineEventType _parseType(String action, Map<String, dynamic>? newValues) {
    switch (action) {
      case 'created':                return TimelineEventType.jobCreated;
      case 'archived':               return TimelineEventType.archived;
      case 'correction_requested':   return TimelineEventType.correctionRequested;
      case 'updated':
        if (newValues?.containsKey('payment_status') == true) {
          return TimelineEventType.paymentChanged;
        }
        if (newValues?.containsKey('status') == true) {
          return TimelineEventType.statusChanged;
        }
        return TimelineEventType.jobEdited;
      case 'status_changed':         return TimelineEventType.statusChanged;
      default:                       return TimelineEventType.jobEdited;
    }
  }

  String _buildDescription(TimelineEventType type, String jobLabel, JobAuditEntryEntity entry) {
    switch (type) {
      case TimelineEventType.jobCreated:
        return 'Logged: $jobLabel';
      case TimelineEventType.statusChanged:
        final newStatus = entry.newValues?['status'] as String? ?? '';
        return '$jobLabel → $newStatus'.toUpperCase();
      case TimelineEventType.paymentChanged:
        final newPayment = entry.newValues?['payment_status'] as String? ?? '';
        return '$jobLabel marked $newPayment'.toUpperCase();
      case TimelineEventType.archived:
        return 'Archived: $jobLabel';
      case TimelineEventType.correctionRequested:
        return 'Correction requested on $jobLabel';
      case TimelineEventType.jobEdited:
        return 'Edited: $jobLabel';
      case TimelineEventType.followUpSent:
        return 'Follow-up sent for $jobLabel';
    }
  }
}

final timelineProvider = StateNotifierProvider<TimelineNotifier, TimelineState>(
  (_) => TimelineNotifier());
