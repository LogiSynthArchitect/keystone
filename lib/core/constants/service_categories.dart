/// Standardized service categories enforced across the system.
///
/// Every service type must belong to one of these categories.
/// No free-text categorization — users pick from this list.
class ServiceCategory {
  final String key;
  final String display;
  final String emoji;
  final String defaultIconName;
  final String description;

  const ServiceCategory({
    required this.key,
    required this.display,
    required this.emoji,
    required this.defaultIconName,
    required this.description,
  });

  static const List<ServiceCategory> all = [
    ServiceCategory(
      key: 'Automotive',
      display: 'AUTOMOTIVE',
      emoji: '🚗',
      defaultIconName: 'car',
      description: 'Vehicle lock & key services',
    ),
    ServiceCategory(
      key: 'Residential',
      display: 'RESIDENTIAL',
      emoji: '🏠',
      defaultIconName: 'lock',
      description: 'Home & apartment services',
    ),
    ServiceCategory(
      key: 'Commercial',
      display: 'COMMERCIAL',
      emoji: '🏢',
      defaultIconName: 'building',
      description: 'Business & office services',
    ),
    ServiceCategory(
      key: 'Security Systems',
      display: 'SECURITY SYSTEMS',
      emoji: '📡',
      defaultIconName: 'video',
      description: 'CCTV, alarms, access control',
    ),
    ServiceCategory(
      key: 'Specialty',
      display: 'SPECIALTY',
      emoji: '⚡',
      defaultIconName: 'unlock',
      description: 'Safe, gate, high-security',
    ),
  ];

  static ServiceCategory? fromKey(String key) {
    for (final c in all) {
      if (c.key == key) return c;
    }
    return null;
  }

  static bool isValid(String key) => fromKey(key) != null;
}
