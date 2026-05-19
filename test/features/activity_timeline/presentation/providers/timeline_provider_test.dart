import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/features/activity_timeline/presentation/providers/timeline_provider.dart';
import 'package:keystone/features/job_logging/domain/entities/job_audit_entry_entity.dart';

void main() {
  group('TimelineEventType labels', () {
    test('jobCreated has correct label', () {
      expect(TimelineEventType.jobCreated.label, equals('JOB LOGGED'));
    });

    test('jobEdited has correct label', () {
      expect(TimelineEventType.jobEdited.label, equals('JOB EDITED'));
    });

    test('statusChanged has correct label', () {
      expect(TimelineEventType.statusChanged.label, equals('STATUS CHANGED'));
    });

    test('paymentChanged has correct label', () {
      expect(TimelineEventType.paymentChanged.label, equals('PAYMENT UPDATED'));
    });

    test('archived has correct label', () {
      expect(TimelineEventType.archived.label, equals('JOB ARCHIVED'));
    });

    test('correctionRequested has correct label', () {
      expect(TimelineEventType.correctionRequested.label, equals('CORRECTION REQUESTED'));
    });

    test('followUpSent has correct label', () {
      expect(TimelineEventType.followUpSent.label, equals('FOLLOW-UP SENT'));
    });
  });

  group('TimelineEvent', () {
    test('creates with required fields', () {
      final event = TimelineEvent(
        id: 'e1',
        jobId: 'j1',
        description: 'Logged: door lock',
        timestamp: DateTime(2026, 5, 13),
        type: TimelineEventType.jobCreated,
      );

      expect(event.id, equals('e1'));
      expect(event.jobId, equals('j1'));
      expect(event.description, equals('Logged: door lock'));
      expect(event.type, equals(TimelineEventType.jobCreated));
    });

    test('accepts optional details', () {
      final event = TimelineEvent(
        id: 'e2',
        jobId: 'j2',
        description: 'PAYMENT UPDATED',
        timestamp: DateTime(2026, 5, 13),
        type: TimelineEventType.paymentChanged,
        details: {'payment_status': 'paid'},
      );

      expect(event.details, isNotNull);
      expect(event.details!['payment_status'], equals('paid'));
    });
  });

  group('TimelineState', () {
    test('defaults to empty events', () {
      const state = TimelineState();
      expect(state.events, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('stores events correctly', () {
      final events = [
        TimelineEvent(
          id: 'e1', jobId: 'j1', description: 'test',
          timestamp: DateTime(2026, 5, 13), type: TimelineEventType.jobCreated,
        ),
      ];
      const loading = true;
      final state = TimelineState(events: events, isLoading: loading);

      expect(state.events.length, equals(1));
      expect(state.isLoading, isTrue);
    });
  });
}
