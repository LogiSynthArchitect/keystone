import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/job_logging/domain/usecases/sync_offline_jobs_usecase.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late SyncOfflineJobsUsecase usecase;
  late MockJobRepository mockRepository;

  setUp(() {
    mockRepository = MockJobRepository();
    usecase = SyncOfflineJobsUsecase(mockRepository);
  });

  group('SyncOfflineJobsUsecase', () {
    test('calls syncPendingJobs on repository', () async {
      // TODO
    });

    test('does nothing when no pending jobs exist', () async {
      // TODO
    });

    test('does nothing when offline', () async {
      // TODO
    });
  });
}
