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

  final updatedJob = JobEntity(
    id: jobId,
    userId: editedBy,
    customerId: 'cust-123',
    serviceType: 'car_lock_programming',
    jobDate: DateTime.now(),
    notes: 'Updated notes',
    status: 'completed',
    followUpSent: false,
    syncStatus: SyncStatus.pending,
    isArchived: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  test('calls repository.editJob with correct params', () async {
    when(() => mockRepository.editJob(any(), any(), any()))
        .thenAnswer((_) async => updatedJob);

    final result = await usecase(EditJobParams(
      jobId: jobId,
      changes: changes,
      editedBy: editedBy,
    ));

    expect(result, equals(updatedJob));
    verify(() => mockRepository.editJob(jobId, changes, editedBy)).called(1);
  });
}
