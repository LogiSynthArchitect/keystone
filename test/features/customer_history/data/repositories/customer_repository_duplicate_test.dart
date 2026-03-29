import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keystone/core/errors/duplicate_customer_exception.dart';
import 'package:keystone/features/customer_history/data/repositories/customer_repository_impl.dart';
import 'package:keystone/features/customer_history/data/models/customer_model.dart';
import 'package:keystone/features/customer_history/domain/entities/customer_entity.dart';
import 'package:keystone/features/customer_history/data/datasources/customer_local_datasource.dart';
import 'package:keystone/features/customer_history/data/datasources/customer_remote_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_local_datasource.dart';
import 'package:keystone/core/constants/app_enums.dart';
import '../../../../helpers/mocks.dart';

class MockCustomerLocal extends Mock implements CustomerLocalDatasource {}
class MockCustomerRemote extends Mock implements CustomerRemoteDatasource {}
class MockJobLocal extends Mock implements JobLocalDatasource {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class _FakeUser extends Fake implements User {
  _FakeUser(this.id);
  @override
  final String id;
}

void main() {
  late CustomerRepositoryImpl repository;
  late MockCustomerLocal mockLocal;
  late MockCustomerRemote mockRemote;
  late MockConnectivityService mockConnectivity;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockJobLocal mockJobLocal;

  setUpAll(() {
    registerFallbackValue(CustomerModel(
      id: 'fb', userId: 'u0', fullName: 'FB', phoneNumber: '0000000000',
      totalJobs: 0, syncStatus: SyncStatus.pending,
      createdAt: '2024-01-01T00:00:00Z', updatedAt: '2024-01-01T00:00:00Z',
    ));
  });

  setUp(() {
    mockLocal = MockCustomerLocal();
    mockRemote = MockCustomerRemote();
    mockConnectivity = MockConnectivityService();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockJobLocal = MockJobLocal();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(_FakeUser('test-user-id'));

    repository = CustomerRepositoryImpl(
      mockRemote, mockLocal, mockConnectivity, mockSupabase, mockJobLocal,
    );
  });

  final existingModel = CustomerModel(
    id: 'existing-uuid',
    userId: 'test-user-id',
    fullName: 'Kwame Mensah',
    phoneNumber: '0201234567',
    totalJobs: 2,
    syncStatus: SyncStatus.synced,
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
  );

  group('DuplicateCustomerException', () {
    test('createCustomer throws when phone number already exists for same user', () async {
      when(() => mockLocal.getCustomers()).thenAnswer((_) async => [existingModel]);

      final newCustomer = CustomerEntity(
        id: '', userId: 'test-user-id', fullName: 'Other Person',
        phoneNumber: '0201234567',
        totalJobs: 0, syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );

      expect(
        () async => repository.createCustomer(newCustomer),
        throwsA(isA<DuplicateCustomerException>()
          .having((e) => e.existingCustomerId, 'existingCustomerId', 'existing-uuid')
          .having((e) => e.existingCustomerName, 'existingCustomerName', 'Kwame Mensah')),
      );
    });

    test('createCustomer succeeds when phone number is unique', () async {
      when(() => mockLocal.getCustomers()).thenAnswer((_) async => [existingModel]);
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.saveCustomer(any())).thenAnswer((_) async {});

      final newCustomer = CustomerEntity(
        id: '', userId: 'test-user-id', fullName: 'New Person',
        phoneNumber: '0209999999',
        totalJobs: 0, syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );

      final result = await repository.createCustomer(newCustomer);
      expect(result.phoneNumber, equals('0209999999'));
    });
  });
}
