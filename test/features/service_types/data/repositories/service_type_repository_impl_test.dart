import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/service_types/data/repositories/service_type_repository_impl.dart';
import 'package:keystone/features/service_types/domain/entities/service_type_entity.dart';
import 'package:keystone/features/service_types/data/models/service_type_model.dart';
import 'package:keystone/features/service_types/data/datasources/service_type_local_datasource.dart';
import 'package:keystone/features/service_types/data/datasources/service_type_remote_datasource.dart';
import '../../../../helpers/mocks.dart';

class MockServiceTypeRemote extends Mock implements ServiceTypeRemoteDatasource {}
class MockServiceTypeLocal extends Mock implements ServiceTypeLocalDatasource {}

void main() {
  late ServiceTypeRepositoryImpl repository;
  late MockServiceTypeRemote mockRemote;
  late MockServiceTypeLocal mockLocal;
  late MockConnectivityService mockConnectivity;

  setUpAll(() {
    registerFallbackValue(ServiceTypeModel(
      id: 'fallback', userId: 'u0', name: 'Fallback',
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
    ));
  });

  setUp(() {
    mockRemote = MockServiceTypeRemote();
    mockLocal = MockServiceTypeLocal();
    mockConnectivity = MockConnectivityService();
    repository = ServiceTypeRepositoryImpl(mockRemote, mockLocal, mockConnectivity);
  });

  final now = DateTime.now();
  final entity = ServiceTypeEntity(
    id: '1', userId: 'u1', name: 'Test', createdAt: now, updatedAt: now
  );
  final model = ServiceTypeModel.fromEntity(entity);

  group('ServiceTypeRepository', () {
    test('getServiceTypes syncs when online', () async {
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.getServiceTypes()).thenAnswer((_) async => [model]);
      when(() => mockLocal.clear()).thenAnswer((_) async {});
      when(() => mockLocal.saveServiceTypes(any())).thenAnswer((_) async {});
      when(() => mockLocal.getServiceTypes()).thenAnswer((_) async => [model]);

      final result = await repository.getServiceTypes();

      expect(result.first.id, equals('1'));
      verify(() => mockRemote.getServiceTypes()).called(1);
      verify(() => mockLocal.saveServiceTypes(any())).called(1);
    });

    test('getServiceTypes returns local when offline', () async {
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.getServiceTypes()).thenAnswer((_) async => [model]);

      final result = await repository.getServiceTypes();

      expect(result.first.id, equals('1'));
      verifyNever(() => mockRemote.getServiceTypes());
    });

    test('createServiceType saves local first, then syncs remote when online', () async {
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => true);
      when(() => mockLocal.saveServiceType(any())).thenAnswer((_) async {});
      when(() => mockRemote.createServiceType(any())).thenAnswer((_) async => model);

      final result = await repository.createServiceType(entity);

      expect(result.id, equals('1'));
      verify(() => mockLocal.saveServiceType(any())).called(2); // once before remote, once after
      verify(() => mockRemote.createServiceType(any())).called(1);
    });
  });
}
