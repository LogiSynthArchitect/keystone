import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/job_logging/domain/usecases/update_payment_status_usecase.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/core/constants/app_enums.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late UpdatePaymentStatusUsecase usecase;
  late MockJobRepository mockRepository;

  final now = DateTime.now();
  final existingJob = JobEntity(
    id: 'job-1',
    userId: 'user-1',
    customerId: 'cust-1',
    serviceType: 'car_lock',
    jobDate: now,
    followUpSent: false,
    syncStatus: SyncStatus.pending,
    isArchived: false,
    status: 'completed',
    paymentStatus: 'unpaid',
    createdAt: now,
    updatedAt: now,
  );

  final updatedJob = existingJob.copyWith(paymentStatus: 'paid', paymentMethod: 'cash');

  setUp(() {
    mockRepository = MockJobRepository();
    usecase = UpdatePaymentStatusUsecase(mockRepository);
  });

  test('delegates to repository.updatePaymentStatus with correct params', () async {
    when(() => mockRepository.getJobById('job-1')).thenAnswer((_) async => existingJob);
    when(() => mockRepository.updatePaymentStatus('job-1', 'paid', 'cash', 'user-1'))
        .thenAnswer((_) async => updatedJob);

    final result = await usecase(const UpdatePaymentStatusParams(
      jobId: 'job-1',
      paymentStatus: 'paid',
      paymentMethod: 'cash',
      editedBy: 'user-1',
    ));

    expect(result.paymentStatus, equals('paid'));
    verify(() => mockRepository.getJobById('job-1')).called(1);
    verify(() => mockRepository.updatePaymentStatus('job-1', 'paid', 'cash', 'user-1')).called(1);
  });

  test('passes null paymentMethod when not provided', () async {
    when(() => mockRepository.getJobById('job-1')).thenAnswer((_) async => existingJob);
    when(() => mockRepository.updatePaymentStatus('job-1', 'unpaid', null, 'user-1'))
        .thenAnswer((_) async => existingJob);

    await usecase(const UpdatePaymentStatusParams(
      jobId: 'job-1',
      paymentStatus: 'unpaid',
      editedBy: 'user-1',
    ));

    verify(() => mockRepository.getJobById('job-1')).called(1);
    verify(() => mockRepository.updatePaymentStatus('job-1', 'unpaid', null, 'user-1')).called(1);
  });

  test('propagates exception from repository', () async {
    when(() => mockRepository.getJobById('job-1')).thenAnswer((_) async => existingJob);
    when(() => mockRepository.updatePaymentStatus(any(), any(), any(), any()))
        .thenThrow(Exception('network error'));

    expect(
      () => usecase(const UpdatePaymentStatusParams(
        jobId: 'job-1',
        paymentStatus: 'paid',
        editedBy: 'user-1',
      )),
      throwsA(isA<Exception>()),
    );
  });

  test('throws when job not found', () async {
    when(() => mockRepository.getJobById('job-1')).thenAnswer((_) async => null);

    expect(
      () => usecase(const UpdatePaymentStatusParams(
        jobId: 'job-1',
        paymentStatus: 'paid',
        editedBy: 'user-1',
      )),
      throwsA(isA<Exception>()),
    );
  });

  test('throws when payment status not allowed for current job status', () async {
    final quotedJob = existingJob.copyWith(status: 'quoted', paymentStatus: 'unpaid');
    when(() => mockRepository.getJobById('job-1')).thenAnswer((_) async => quotedJob);

    expect(
      () => usecase(const UpdatePaymentStatusParams(
        jobId: 'job-1',
        paymentStatus: 'paid',
        editedBy: 'user-1',
      )),
      throwsA(isA<Exception>()),
    );
  });
}
