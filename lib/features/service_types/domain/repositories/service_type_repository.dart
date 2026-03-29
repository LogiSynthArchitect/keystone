import '../entities/service_type_entity.dart';

abstract class ServiceTypeRepository {
  Future<List<ServiceTypeEntity>> getServiceTypes();
  Future<ServiceTypeEntity> createServiceType(ServiceTypeEntity serviceType);
  Future<ServiceTypeEntity> updateServiceType(ServiceTypeEntity serviceType);
  Future<void> deleteServiceType(String id);
  Future<void> syncServiceTypes();
}
