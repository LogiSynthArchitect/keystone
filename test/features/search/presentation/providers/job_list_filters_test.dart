import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/core/constants/app_enums.dart';

JobEntity _makeJob({
  required String id,
  String status = 'completed',
  String paymentStatus = 'unpaid',
  String serviceType = 'car lock',
  DateTime? jobDate,
  int? amountCharged,
}) {
  final now = DateTime.now();
  return JobEntity(
    id: id,
    userId: 'user-1',
    customerId: 'cust-1',
    serviceType: serviceType,
    jobDate: jobDate ?? now,
    followUpSent: false,
    syncStatus: SyncStatus.synced,
    isArchived: false,
    status: status,
    paymentStatus: paymentStatus,
    amountCharged: amountCharged,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('JobListFilters', () {
    final jobs = [
      _makeJob(id: '1', status: 'completed', paymentStatus: 'paid',   serviceType: 'car lock'),
      _makeJob(id: '2', status: 'in_progress', paymentStatus: 'unpaid', serviceType: 'door lock'),
      _makeJob(id: '3', status: 'completed', paymentStatus: 'unpaid', serviceType: 'car lock'),
      _makeJob(id: '4', status: 'quoted',    paymentStatus: 'unpaid', serviceType: 'safe'),
    ];

    JobListState stateWith(List<JobEntity> activeJobs) =>
        JobListState(activeJobs: activeJobs);

    test('no filters returns all active jobs', () {
      final state = stateWith(jobs);
      expect(state.filteredJobs, equals(jobs));
    });

    test('filter by status returns only matching jobs', () {
      final state = stateWith(jobs).copyWith(
        filters: const JobListFilters(status: 'completed'),
      );
      expect(state.filteredJobs.length, equals(2));
      expect(state.filteredJobs.every((j) => j.status == 'completed'), isTrue);
    });

    test('filter by paymentStatus returns only matching jobs', () {
      final state = stateWith(jobs).copyWith(
        filters: const JobListFilters(paymentStatus: 'paid'),
      );
      expect(state.filteredJobs.length, equals(1));
      expect(state.filteredJobs.first.id, equals('1'));
    });

    test('filter by serviceType returns only matching jobs', () {
      final state = stateWith(jobs).copyWith(
        filters: const JobListFilters(serviceType: 'car lock'),
      );
      expect(state.filteredJobs.length, equals(2));
      expect(state.filteredJobs.every((j) => j.serviceType == 'car lock'), isTrue);
    });

    test('stacked filters narrow results', () {
      final state = stateWith(jobs).copyWith(
        filters: const JobListFilters(status: 'completed', paymentStatus: 'unpaid'),
      );
      expect(state.filteredJobs.length, equals(1));
      expect(state.filteredJobs.first.id, equals('3'));
    });

    test('filter by date range excludes jobs outside range', () {
      final now = DateTime.now();
      final jobsWithDates = [
        _makeJob(id: 'old', jobDate: DateTime(2024, 1, 15)),
        _makeJob(id: 'new', jobDate: now),
      ];
      final range = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
      final state = stateWith(jobsWithDates).copyWith(
        filters: JobListFilters(dateRange: range),
      );
      expect(state.filteredJobs.length, equals(1));
      expect(state.filteredJobs.first.id, equals('new'));
    });

    test('filters.hasActive is false when no filters set', () {
      expect(const JobListFilters().hasActive, isFalse);
    });

    test('filters.hasActive is true when any filter is set', () {
      expect(const JobListFilters(status: 'completed').hasActive, isTrue);
    });

    test('filters.activeCount counts set filters', () {
      const f = JobListFilters(status: 'completed', paymentStatus: 'unpaid');
      expect(f.activeCount, equals(2));
    });
  });
}
