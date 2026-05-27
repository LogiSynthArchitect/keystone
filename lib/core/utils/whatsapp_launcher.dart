import 'package:url_launcher/url_launcher.dart';
import '../errors/network_exception.dart';
import 'phone_formatter.dart';

class WhatsAppLauncher {
  WhatsAppLauncher._();

  /// Opens WhatsApp chat with the given phone and message.
  ///
  /// [phoneNumber] can be in any common format:
  ///   - International: `+233241234567`
  ///   - Local: `0241234567`
  ///   - Bare: `233241234567`
  ///
  /// If the number starts with `+`, it's used as-is (supports any country).
  /// Otherwise, [PhoneFormatter.normalize] converts Ghana formats to `+233...`.
  /// The leading `+` is stripped for the `wa.me` URL (digits only).
  static Future<bool> openChat({
    required String phoneNumber,
    required String message,
  }) async {
    // Already in international format — use as-is (supports non-Ghana numbers too).
    // Otherwise, normalize through PhoneFormatter (Ghana formats only).
    final normalized = phoneNumber.startsWith('+')
        ? phoneNumber
        : PhoneFormatter.normalize(phoneNumber);
    final cleanPhone = normalized.replaceAll('+', '');
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
