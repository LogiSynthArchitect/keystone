import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/job_logging/data/models/job_audit_entry_model.dart';
import 'package:keystone/features/job_logging/domain/entities/job_audit_entry_entity.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
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

  const TimelineState({
    this.events = const [],
    this.isLoading = false,
    this.errorMessage,
  });
}

class TimelineNotifier extends StateNotifier<TimelineState> {
  final Ref _ref;

  TimelineNotifier(this._ref) : super(const TimelineState()) {
    load();
  }

  Future<void> load() async {
    state = const TimelineState(isLoading: true);
    try {
      // Read all audit entries from Hive directly
      final allEntries = HiveService.jobAuditLog.values
          .map((e) => JobAuditEntryModel.fromJson(Map<String, dynamic>.from(e)).toEntity())
          .toList();

      // Build job lookup for descriptions
      final jobMap = <String, JobEntity>{
        for (final j in _ref.read(jobListProvider).allJobs) j.id: j,
      };

      // Convert audit entries to timeline events, take most recent 50
      allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recent = allEntries.take(50).toList();

      final events = recent.map((entry) => _toEvent(entry, jobMap)).toList();

      state = TimelineState(events: events);
    } catch (e) {
      state = TimelineState(errorMessage: 'Could not load activity.');
    }
  }

  TimelineEvent _toEvent(JobAuditEntryEntity entry, Map<String, JobEntity> jobMap) {
    final job = jobMap[entry.jobId];
    final jobLabel = job?.serviceType ?? 'Job';
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

final timelineProvider = StateNotifierProvider.autoDispose<TimelineNotifier, TimelineState>(
  (ref) => TimelineNotifier(ref));
