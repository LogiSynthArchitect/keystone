import '../entities/service_type_entity.dart';

abstract class ServiceTypeRepository {
  Future<List<ServiceTypeEntity>> getServiceTypes();
  Future<ServiceTypeEntity> createServiceType(ServiceTypeEntity serviceType);
  Future<void> syncServiceTypes();
}
