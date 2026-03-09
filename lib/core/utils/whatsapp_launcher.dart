import 'package:url_launcher/url_launcher.dart';

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

    return _fallbackToSms(phoneNumber: phoneNumber, message: message);
  }

  static Future<bool> _fallbackToSms({
    required String phoneNumber,
    required String message,
  }) async {
    final smsUrl = Uri.parse(
      'sms:$phoneNumber?body=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(smsUrl)) {
      await launchUrl(smsUrl);
      return true;
    }

    return false;
  }
}
