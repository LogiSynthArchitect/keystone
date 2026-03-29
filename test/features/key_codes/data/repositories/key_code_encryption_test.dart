import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/key_codes/data/repositories/key_code_repository_impl.dart';
import 'package:keystone/features/customer_history/domain/entities/key_code_entry_entity.dart';

import 'package:keystone/features/key_codes/data/datasources/key_code_local_datasource.dart';
import 'package:keystone/features/key_codes/data/datasources/key_code_remote_datasource.dart';
import 'package:keystone/features/key_codes/data/models/key_code_entry_model.dart';
import '../../../../helpers/mocks.dart';

class MockKeyCodeLocal extends Mock implements KeyCodeLocalDatasource {}
class MockKeyCodeRemote extends Mock implements KeyCodeRemoteDatasource {}

void main() {
  late KeyCodeRepositoryImpl repository;
  late MockKeyCodeLocal mockLocal;
  late MockKeyCodeRemote mockRemote;
  late MockConnectivityService mockConnectivity;

  const testUserId = 'user-abc-123';

  setUpAll(() {
    registerFallbackValue(KeyCodeEntryModel(
      id: 'fb', customerId: 'c0', keyCode: 'X', createdAt: '2024-01-01T00:00:00Z',
    ));
  });

  setUp(() {
    mockLocal = MockKeyCodeLocal();
    mockRemote = MockKeyCodeRemote();
    mockConnectivity = MockConnectivityService();
    repository = KeyCodeRepositoryImpl(mockLocal, mockRemote, mockConnectivity, testUserId);
  });

  group('Key code encryption', () {
    test('bitting data is NOT stored in plaintext locally', () async {
      const plainBitting = '4-3-2-1-2-3';

      KeyCodeEntryModel? savedModel;
      when(() => mockLocal.save(any())).thenAnswer((invocation) async {
        savedModel = invocation.positionalArguments[0] as KeyCodeEntryModel;
      });
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => false);

      final entry = KeyCodeEntryEntity(
        id: 'test-id',
        customerId: 'cust-1',
        keyCode: 'B276',
        bitting: plainBitting,
        createdAt: DateTime.now(),
      );

      await repository.createKeyCode(entry);

      expect(savedModel, isNotNull);
      expect(savedModel!.bitting, isNotNull);
      expect(savedModel!.bitting, isNot(equals(plainBitting)),
          reason: 'Bitting data must not be stored as plaintext');
      expect(savedModel!.bitting!.contains(':'), isTrue,
          reason: 'Encrypted format is IV:ciphertext separated by colon');
    });

    test('bitting data round-trips correctly through encrypt/decrypt', () async {
      const plainBitting = '5-1-4-2-3';

      KeyCodeEntryModel? savedModel;
      when(() => mockLocal.save(any())).thenAnswer((invocation) async {
        savedModel = invocation.positionalArguments[0] as KeyCodeEntryModel;
      });
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.getForCustomer(any())).thenAnswer((_) async {
        return savedModel != null ? [savedModel!] : [];
      });

      final entry = KeyCodeEntryEntity(
        id: 'test-id-2',
        customerId: 'cust-2',
        keyCode: 'KW1',
        bitting: plainBitting,
        createdAt: DateTime.now(),
      );

      await repository.createKeyCode(entry);

      final retrieved = await repository.getKeyCodesForCustomer('cust-2');
      expect(retrieved.first.bitting, equals(plainBitting),
          reason: 'Decrypted bitting must match original plaintext');
    });
  });
}
