import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/service_type_model.dart';

class ServiceTypeLocalDatasource {
  Box<Map> get _box => HiveService.serviceTypes;

  Future<void> saveServiceTypes(List<ServiceTypeModel> types) async {
    final Map<String, Map> map = {
      for (var t in types) t.id: t.toJson(),
    };
    await _box.putAll(map);
    await _box.flush();
  }

  Future<void> saveServiceType(ServiceTypeModel type) async {
    await _box.put(type.id, type.toJson());
    await _box.flush();
  }

  Future<void> deleteServiceType(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  Future<List<ServiceTypeModel>> getServiceTypes() async {
    return _box.values
        .map((json) => ServiceTypeModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> clear() async {
    await _box.clear();
    await _box.flush();
  }
}
