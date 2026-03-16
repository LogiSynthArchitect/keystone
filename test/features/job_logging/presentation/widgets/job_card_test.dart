import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/features/job_logging/presentation/widgets/job_card.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/core/constants/app_enums.dart';

void main() {
  final fakeJob = JobEntity(
    id: 'job-123',
    userId: 'user-123',
    customerId: 'customer-123',
    serviceType: ServiceType.carLockProgramming,
    jobDate: DateTime.now(),
    followUpSent: false,
    syncStatus: SyncStatus.pending,
    isArchived: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('JobCard widget', () {
    testWidgets('renders service type label', (tester) async {
      // TODO
    });

    testWidgets('renders date', (tester) async {
      // TODO
    });

    testWidgets('shows follow up sent badge when followUpSent is true', (tester) async {
      // TODO
    });

    testWidgets('shows saving badge when sync status is pending', (tester) async {
      // TODO
    });

    testWidgets('calls onTap when tapped', (tester) async {
      // TODO
    });
  });
}
