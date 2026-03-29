import '../../../customer_history/domain/entities/key_code_entry_entity.dart';

abstract class KeyCodeRepository {
  Future<List<KeyCodeEntryEntity>> getKeyCodesForCustomer(String customerId);
  Future<KeyCodeEntryEntity> createKeyCode(KeyCodeEntryEntity entry);
  Future<KeyCodeEntryEntity> updateKeyCode(KeyCodeEntryEntity entry);
  Future<void> deleteKeyCode(String id);
}
