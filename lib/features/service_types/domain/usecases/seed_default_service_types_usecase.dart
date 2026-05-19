import 'package:uuid/uuid.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/service_type_entity.dart';
import '../repositories/service_type_repository.dart';

class SeedDefaultServiceTypesUseCase implements UseCase<void, String> {
  final ServiceTypeRepository _repository;
  SeedDefaultServiceTypesUseCase(this._repository);

  @override
  Future<void> call(String userId) async {
    final now = DateTime.now();
    final uuid = const Uuid();
    final defaults = [
      // AUTOMOTIVE
      _type(uuid.v4(), userId, 'Car Key Replacement',        'Automotive', 'car', now),
      _type(uuid.v4(), userId, 'Transponder Key Programming','Automotive', 'car', now),
      _type(uuid.v4(), userId, 'Car Lockout',                'Automotive', 'unlock', now),
      _type(uuid.v4(), userId, 'Trunk/Boot Unlock',          'Automotive', 'unlock', now),
      _type(uuid.v4(), userId, 'Key Fob Programming',        'Automotive', 'wifi', now),
      _type(uuid.v4(), userId, 'Ignition Repair',            'Automotive', 'key', now),
      _type(uuid.v4(), userId, 'Broken Key Extraction',      'Automotive', 'tools', now),
      _type(uuid.v4(), userId, 'Motorcycle Keys',            'Automotive', 'motorcycle', now),
      // RESIDENTIAL
      _type(uuid.v4(), userId, 'House Lockout',              'Residential', 'door-open', now),
      _type(uuid.v4(), userId, 'Lock Installation',          'Residential', 'lock', now),
      _type(uuid.v4(), userId, 'Lock Rekeying',              'Residential', 'key', now),
      _type(uuid.v4(), userId, 'Lock Repair',                'Residential', 'wrench', now),
      _type(uuid.v4(), userId, 'Key Duplication',            'Residential', 'key', now),
      _type(uuid.v4(), userId, 'Smart Lock Install',         'Residential', 'mobile-alt', now),
      _type(uuid.v4(), userId, 'Garage Door Locks',          'Residential', 'lock', now),
      _type(uuid.v4(), userId, 'Padlock Sales/Installation', 'Residential', 'lock', now),
      _type(uuid.v4(), userId, 'Mailbox Locks',              'Residential', 'envelope', now),
      _type(uuid.v4(), userId, 'Window Locks',               'Residential', 'lock', now),
      // COMMERCIAL
      _type(uuid.v4(), userId, 'Commercial Lockout',         'Commercial', 'building', now),
      _type(uuid.v4(), userId, 'Master Key Systems',         'Commercial', 'network-wired', now),
      _type(uuid.v4(), userId, 'Panic Bar Installation',     'Commercial', 'door-closed', now),
      _type(uuid.v4(), userId, 'Door Closer Install',        'Commercial', 'tools', now),
      _type(uuid.v4(), userId, 'Electric Strike Installation','Commercial', 'bolt', now),
      _type(uuid.v4(), userId, 'High-Security Locks',        'Commercial', 'shield-alt', now),
      _type(uuid.v4(), userId, 'File Cabinet Locks',         'Commercial', 'archive', now),
      _type(uuid.v4(), userId, 'Storefront Locks',           'Commercial', 'store', now),
      // SECURITY SYSTEMS
      _type(uuid.v4(), userId, 'CCTV Installation',          'Security Systems', 'video', now),
      _type(uuid.v4(), userId, 'Video Doorbell Installation','Security Systems', 'video', now),
      _type(uuid.v4(), userId, 'Access Control',             'Security Systems', 'id-card', now),
      _type(uuid.v4(), userId, 'Burglar Alarms',             'Security Systems', 'bell', now),
      _type(uuid.v4(), userId, 'Intercom Systems',           'Security Systems', 'phone', now),
      _type(uuid.v4(), userId, 'Electric Gate Motor Repair', 'Security Systems', 'tools', now),
      _type(uuid.v4(), userId, 'Electric Fence Installation', 'Security Systems', 'bolt', now),
      _type(uuid.v4(), userId, 'Rolling Shutter Repair',     'Security Systems', 'wrench', now),
      // SPECIALTY
      _type(uuid.v4(), userId, 'Key Cutting',               'Specialty', 'cut', now),
      _type(uuid.v4(), userId, 'Safe Opening',              'Specialty', 'unlock', now),
      _type(uuid.v4(), userId, 'Safe Installation',         'Specialty', 'lock', now),
      _type(uuid.v4(), userId, 'Gate Automation',           'Specialty', 'tools', now),
      _type(uuid.v4(), userId, 'Eviction Services',         'Specialty', 'gavel', now),
    ];

    for (final service in defaults) {
      await _repository.createServiceType(service);
    }
  }

  ServiceTypeEntity _type(String id, String userId, String name, String category, String iconName, DateTime now) {
    return ServiceTypeEntity(
      id: id,
      userId: userId,
      name: name,
      category: category,
      iconName: iconName,
      isDefault: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}
