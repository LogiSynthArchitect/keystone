import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/job_logging/domain/usecases/edit_job_usecase.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/core/constants/app_enums.dart';
import '../../../../helpers/mocks.dart';

class FakeJob extends Fake implements JobEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeJob());
  });

  late EditJobUsecase usecase;
  late MockJobRepository mockRepository;

  setUp(() {
    mockRepository = MockJobRepository();
    usecase = EditJobUsecase(mockRepository);
  });

  final jobId = 'job-123';
  final editedBy = 'user-123';
  final changes = {'notes': 'Updated notes', 'status': 'completed'};

  final now = DateTime.now();
  final existingJob = JobEntity(
    id: jobId,
    userId: editedBy,
    customerId: 'cust-123',
    serviceType: 'car_lock_programming',
    jobDate: now,
    status: 'in_progress',
    paymentStatus: 'unpaid',
    followUpSent: false,
    syncStatus: SyncStatus.pending,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  final updatedJob = existingJob.copyWith(
    notes: 'Updated notes',
    status: 'completed',
  );

  test('calls repository.editJob with correct params', () async {
    when(() => mockRepository.getJobById(jobId)).thenAnswer((_) async => existingJob);
    when(() => mockRepository.editJob(any(), any(), any()))
        .thenAnswer((_) async => updatedJob);

    final result = await usecase(EditJobParams(
      jobId: jobId,
      changes: changes,
      editedBy: editedBy,
    ));

    expect(result, equals(updatedJob));
    verify(() => mockRepository.getJobById(jobId)).called(1);
    verify(() => mockRepository.editJob(jobId, changes, editedBy)).called(1);
  });

  test('throws when job not found', () async {
    when(() => mockRepository.getJobById(jobId)).thenAnswer((_) async => null);

    expect(
      () => usecase(EditJobParams(
        jobId: jobId,
        changes: changes,
        editedBy: editedBy,
      )),
      throwsA(isA<Exception>()),
    );
  });

  test('throws when paymentStatus in changes is invalid for new status', () async {
    when(() => mockRepository.getJobById(jobId)).thenAnswer((_) async => existingJob);
    final badChanges = {'status': 'quoted', 'paymentStatus': 'paid'};

    expect(
      () => usecase(EditJobParams(
        jobId: jobId,
        changes: badChanges,
        editedBy: editedBy,
      )),
      throwsA(isA<Exception>()),
    );
  });
