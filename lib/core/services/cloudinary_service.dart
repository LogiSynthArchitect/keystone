import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../constants/supabase_constants.dart';

class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = String.fromEnvironment('CLOUDINARY_NAME', defaultValue: '');
  static const String apiKey = String.fromEnvironment('CLOUDINARY_API_KEY', defaultValue: '');
  static const String uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: '');

  static bool get isConfigured =>
      cloudName.isNotEmpty && apiKey.isNotEmpty && uploadPreset.isNotEmpty;

  static String uploadUrlFor(String cn) => 'https://api.cloudinary.com/v1_1/$cn/auto/upload';
  static String get uploadUrl => uploadUrlFor(cloudName);

  /// Edge function URL for signed deletion.
  static String get deleteFunctionUrl {
    final base = SupabaseConstants.url.replaceAll(RegExp(r'/*$'), '');
    return '$base/functions/v1/cloudinary-delete';
  }
}

class CloudinaryService {
  static String? publicIdFromUrl(String url) {
    try {
      final parts = Uri.parse(url).path.split('/');
      final filePart = parts.last;
      final dot = filePart.lastIndexOf('.');
      return dot > 0 ? filePart.substring(0, dot) : null;
    } catch (_) {
      return null;
    }
  }

  /// Extracts resource type segment from a Cloudinary URL.
  static String _resourceTypeFromUrl(String url) {
    if (url.contains('/video/upload/')) return 'video';
    if (url.contains('/raw/upload/')) return 'raw';
    return 'image';
  }

  Future<bool> deleteMedia(String url) async {
    if (!CloudinaryConfig.isConfigured) return false;
    final publicId = publicIdFromUrl(url);
    if (publicId == null) return false;

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(CloudinaryConfig.deleteFunctionUrl));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'public_id': publicId,
        'resource_type': _resourceTypeFromUrl(url),
      }));
      final response = await request.close();
      final respBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(respBody) as Map<String, dynamic>;
      return json['result'] == 'ok';
    } catch (_) {
      debugPrint('[KS:CLOUD] deleteMedia failed for $publicId');
      return false;
    }
  }

  static bool _isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }

  Future<Uint8List> _maybeCompress(File file) async {
    if (!_isImage(file.path)) return file.readAsBytes();
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.path,
        quality: 70,
        minWidth: 1920,
        minHeight: 1920,
      );
      if (compressed != null && compressed.length < (await file.length())) {
        debugPrint('[KS:CLOUD] Compressed ${file.path}: ${await file.length()} → ${compressed.length} bytes');
        return compressed;
      }
    } catch (_) {}
    return file.readAsBytes();
  }

  Future<String?> uploadMedia({
    required File file,
    String? publicId,
  }) async {
    if (!CloudinaryConfig.isConfigured) return null;

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(CloudinaryConfig.uploadUrl));
      request.headers.set('Content-Type', 'multipart/form-data');

      const nl = '\r\n';
      final boundary = '----boundary${DateTime.now().millisecondsSinceEpoch}';
      final body = StringBuffer();

      void writeField(String name, String value) {
        body.write('--$boundary$nl');
        body.write('Content-Disposition: form-data; name="$name"$nl$nl');
        body.write('$value$nl');
      }

      writeField('api_key', CloudinaryConfig.apiKey);
      writeField('upload_preset', CloudinaryConfig.uploadPreset);
      if (publicId != null) writeField('public_id', publicId);

      body.write('--$boundary$nl');
      body.write('Content-Disposition: form-data; name="file"; filename="${file.path.split('/').last}"$nl');
      body.write('Content-Type: application/octet-stream$nl$nl');
      final header = utf8.encode(body.toString());
      final fileBytes = await _maybeCompress(file);
      final footer = utf8.encode('$nl--$boundary--$nl');

      request.contentLength = header.length + fileBytes.length + footer.length;
      request.add(header);
      request.add(fileBytes);
      request.add(footer);

      final response = await request.close();
      final respBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(respBody) as Map<String, dynamic>;

      if (response.statusCode == 200 && json['secure_url'] != null) {
        return json['secure_url'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
