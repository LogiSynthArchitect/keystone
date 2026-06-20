import 'dart:convert';
import 'dart:js' as js;

/// Web implementation — updates HTML meta tags via JS bridge in index.html.
class SeoService {
  SeoService._();

  static void updateProfileMeta({
    required String title,
    required String description,
    String? image,
    String? url,
  }) {
    final payload = jsonEncode({
      'title': title,
      'description': description,
      if (image != null && image.isNotEmpty) 'image': image,
      'url': url ?? js.context.callMethod('window.location.href.toString'),
    });

    js.context.callMethod('__keystoneSeo', [payload]);
  }
}
