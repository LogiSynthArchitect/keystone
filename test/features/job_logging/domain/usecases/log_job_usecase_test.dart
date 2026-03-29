import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/job_logging/domain/usecases/log_job_usecase.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/customer_history/domain/entities/customer_entity.dart';
import 'package:keystone/core/constants/app_enums.dart';
import 'package:keystone/core/errors/validation_exception.dart';
import '../../../../helpers/mocks.dart';

class FakeJob extends Fake implements JobEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeJob());
  });

  late LogJobUsecase usecase;
  late MockJobRepository mockRepository;
  late MockCustomerRepository mockCustomerRepository;

  setUp(() {
    mockRepository = MockJobRepository();
    mockCustomerRepository = MockCustomerRepository();
    usecase = LogJobUsecase(mockRepository, mockCustomerRepository);
    when(() => mockCustomerRepository.getCustomerById(any())).thenAnswer((_) async => throw UnimplementedError('Mocked out by test unless needed'));
  });

  // Adding a dummy customer entity for the tests
  final dummyCustomer = CustomerEntity(
    id: 'customer-123',
    userId: 'user-123',
    fullName: 'Test Customer',
    phoneNumber: '+233541234567',
    totalJobs: 0,
    syncStatus: SyncStatus.synced,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final validParams = LogJobParams(
    userId: 'user-123',
    customerId: 'customer-123',
    serviceType: 'car_lock_programming',
    jobDate: DateTime.now(),
    notes: 'Test job',
    amountCharged: 150,
  );

  final fakeJob = JobEntity(
    id: 'job-123',
    userId: 'user-123',
    customerId: 'customer-123',
    serviceType: 'car_lock_programming',
    jobDate: DateTime.now(),
    followUpSent: false,
    syncStatus: SyncStatus.pending,
    isArchived: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('LogJobUsecase', () {
    setUp(() {
       when(() => mockCustomerRepository.getCustomerById(any())).thenAnswer((_) async => dummyCustomer);
    });

    test('saves job successfully with valid data', () async {
      when(() => mockRepository.createJob(any()))
          .thenAnswer((_) async => fakeJob);

      final result = await usecase(validParams);

      expect(result.id, equals('job-123'));
      expect(result.serviceType, equals('car_lock_programming'));
      verify(() => mockRepository.createJob(any())).called(1);
    });

    test('throws ValidationException when job date is in the future', () async {
      final futureParams = LogJobParams(
        userId: 'user-123',
        customerId: 'customer-123',
        serviceType: 'car_lock_programming',
        jobDate: DateTime.now().add(const Duration(days: 2)),
      );

      expect(
        () => usecase(futureParams),
        throwsA(isA<ValidationException>()),
      );
      verifyNever(() => mockRepository.createJob(any()));
    });

    test('throws ValidationException when amount is zero or negative', () async {
      final zeroAmountParams = LogJobParams(
        userId: 'user-123',
        customerId: 'customer-123',
        serviceType: 'car_lock_programming',
        jobDate: DateTime.now(),
        amountCharged: 0,
      );

      expect(
        () => usecase(zeroAmountParams),
        throwsA(isA<ValidationException>()),
      );
      verifyNever(() => mockRepository.createJob(any()));
    });

    test('throws ValidationException when amount is negative', () async {
      final negativeAmountParams = LogJobParams(
        userId: 'user-123',
        customerId: 'customer-123',
        serviceType: 'car_lock_programming',
        jobDate: DateTime.now(),
        amountCharged: -50,
      );

      expect(
        () => usecase(negativeAmountParams),
        throwsA(isA<ValidationException>()),
      );
      verifyNever(() => mockRepository.createJob(any()));
    });

    test('allows job with no amount charged', () async {
      when(() => mockRepository.createJob(any()))
          .thenAnswer((_) async => fakeJob);

      final noAmountParams = LogJobParams(
        userId: 'user-123',
        customerId: 'customer-123',
        serviceType: 'car_lock_programming',
        jobDate: DateTime.now(),
      );

      final result = await usecase(noAmountParams);
      expect(result, isA<JobEntity>());
      verify(() => mockRepository.createJob(any())).called(1);
    });

    test('allows job dated today', () async {
      when(() => mockRepository.createJob(any()))
          .thenAnswer((_) async => fakeJob);

      final todayParams = LogJobParams(
        userId: 'user-123',
        customerId: 'customer-123',
        serviceType: 'car_lock_programming',
        jobDate: DateTime.now(),
      );

      final result = await usecase(todayParams);
      expect(result, isA<JobEntity>());
    });

    test('created job has pending sync status', () async {
      when(() => mockRepository.createJob(any()))
          .thenAnswer((_) async => fakeJob);

      final result = await usecase(validParams);
      expect(result.syncStatus, equals(SyncStatus.pending));
    });

    test('created job has followUpSent false', () async {
      when(() => mockRepository.createJob(any()))
          .thenAnswer((_) async => fakeJob);

      final result = await usecase(validParams);
      expect(result.followUpSent, isFalse);
    });
  });
}
