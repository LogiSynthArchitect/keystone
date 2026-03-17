import 'package:url_launcher/url_launcher.dart';
import '../errors/network_exception.dart';

class WhatsAppLauncher {
  WhatsAppLauncher._();

  static Future<bool> openChat({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll('+', '');
    final url = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }

    // Task 1 fix: Prevent silent failure to protect state integrity
    throw const NetworkException(
      message: 'WhatsApp is not installed on this device.',
      code: 'WHATSAPP_NOT_INSTALLED',
    );
  }
}
