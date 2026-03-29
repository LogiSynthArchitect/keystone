import '../../../../core/storage/hive_service.dart';
import '../models/key_code_entry_model.dart';

class KeyCodeLocalDatasource {
  Future<List<KeyCodeEntryModel>> getForCustomer(String customerId) async {
    final box = HiveService.keyCodeHistory;
    return box.values
        .map((e) => KeyCodeEntryModel.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.customerId == customerId)
        .toList();
  }

  Future<void> save(KeyCodeEntryModel model) async {
    final box = HiveService.keyCodeHistory;
    await box.put(model.id, model.toJson());
    await box.flush();
  }

  Future<void> delete(String id) async {
    await HiveService.keyCodeHistory.delete(id);
    await HiveService.keyCodeHistory.flush();
  }
}
