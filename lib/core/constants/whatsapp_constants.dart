class WhatsAppConstants {
  WhatsAppConstants._();

  static String buildFollowUpMessage({
    required String customerName,
    required String technicianName,
    required String serviceType,
    required String profileUrl,
  }) {
    final firstName = customerName.split(' ').first;
    final service   = _serviceTypeLabel(serviceType);

    return '''Hello $firstName, this is $technicianName.

Thank you for choosing our $service service today. It was a pleasure working with you.

If you ever need locksmith services again or know someone who does, feel free to reach out or share my profile:
$profileUrl

Have a great day! 🔑''';
  }

  static String _serviceTypeLabel(String serviceType) {
    switch (serviceType) {
      case 'car_lock_programming':    return 'car key programming';
      case 'door_lock_installation':  return 'door lock installation';
      case 'door_lock_repair':        return 'door lock repair';
      case 'smart_lock_installation': return 'smart lock installation';
      default:                        return 'locksmith';
    }
  }
}
