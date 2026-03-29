import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/customer_history/domain/usecases/create_customer_usecase.dart';
import 'package:keystone/features/customer_history/domain/entities/customer_entity.dart';
import 'package:keystone/features/customer_history/domain/repositories/customer_repository.dart';
import 'package:keystone/features/job_logging/domain/usecases/log_job_usecase.dart';
import 'package:keystone/features/job_logging/domain/repositories/job_repository.dart';
import 'package:keystone/core/errors/validation_exception.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}
class MockJobRepository extends Mock implements JobRepository {}

void main() {
  late CreateCustomerUsecase createCustomerUsecase;
  late LogJobUsecase logJobUsecase;
  late MockCustomerRepository mockCustomerRepository;
  late MockJobRepository mockJobRepository;

  setUp(() {
    mockCustomerRepository = MockCustomerRepository();
    mockJobRepository = MockJobRepository();
    createCustomerUsecase = CreateCustomerUsecase(mockCustomerRepository);
    logJobUsecase = LogJobUsecase(mockJobRepository, mockCustomerRepository);
  });

  group('CreateCustomerUsecase Validation Tests', () {
    test('should throw ValidationException for invalid phone number', () async {
      final params = CreateCustomerParams(
        userId: 'user123',
        fullName: 'John Doe',
        phoneNumber: '123', // Too short
      );

      expect(
        () => createCustomerUsecase(params),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'PHONE_INVALID')),
      );
    });

    test('should throw ValidationException if phone number already exists', () async {
      final params = CreateCustomerParams(
        userId: 'user123',
        fullName: 'John Doe',
        phoneNumber: '0241234567',
      );

      final existingCustomer = CustomerEntity(
        id: 'cust123',
        userId: 'user123',
        fullName: 'Existing User',
        phoneNumber: '+233241234567',
        totalJobs: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockCustomerRepository.getCustomerByPhone(any()))
          .thenAnswer((_) async => existingCustomer);

      expect(
        () => createCustomerUsecase(params),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'PHONE_EXISTS')),
      );
    });

    test('should throw ValidationException if name already exists', () async {
      final params = CreateCustomerParams(
        userId: 'user123',
        fullName: 'John Doe',
        phoneNumber: '0241234567',
      );

      when(() => mockCustomerRepository.getCustomerByPhone(any()))
          .thenAnswer((_) async => null);
      
      when(() => mockCustomerRepository.searchCustomers(any()))
          .thenAnswer((_) async => [
            CustomerEntity(
              id: 'cust456',
              userId: 'user123',
              fullName: 'John Doe', // Same name
              phoneNumber: '+233550000000',
              totalJobs: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          ]);

      expect(
        () => createCustomerUsecase(params),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'NAME_EXISTS')),
      );
    });
  });

  group('LogJobUsecase Validation Tests', () {
    test('should throw ValidationException if customer does not exist', () async {
      final params = LogJobParams(
        userId: 'user123',
        customerId: 'non-existent-id',
        serviceType: 'smart_lock_installation',
        jobDate: DateTime.now(),
      );

      when(() => mockCustomerRepository.getCustomerById(any()))
          .thenThrow(Exception('Not found'));

      expect(
        () => logJobUsecase(params),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'CUSTOMER_NOT_FOUND')),
      );
    });
  });
}
