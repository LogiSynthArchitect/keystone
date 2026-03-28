import 'package:url_launcher/url_launcher.dart';
import '../errors/network_exception.dart';

class WhatsAppLauncher {
  WhatsAppLauncher._();

  static Future<bool> openChat({
    required String phoneNumber,
    required String message,
  }) async {
    // Phone must be in international format (e.g. +233241234567).
    // All customer phones are normalized by PhoneFormatter.normalize() on creation.
    // We strip the leading '+' because wa.me expects digits only (e.g. wa.me/233241234567).
    assert(
      phoneNumber.startsWith('+'),
      'WhatsAppLauncher.openChat: phone must be in international format (starts with +). Got: $phoneNumber',
    );
    final cleanPhone = phoneNumber.replaceAll('+', '');
    final url = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }

    throw const NetworkException(
      message: 'WhatsApp is not installed on this device.',
      code: 'WHATSAPP_NOT_INSTALLED',
    );
  }
}
