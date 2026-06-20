/// Stub implementation — no-ops on non-web platforms.
class SeoService {
  SeoService._();

  static void updateProfileMeta({
    String? title,
    String? description,
    String? image,
    String? url,
  }) {
    // No-op on mobile
  }
}
