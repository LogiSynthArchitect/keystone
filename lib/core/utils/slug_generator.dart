class SlugGenerator {
  SlugGenerator._();

  static String generate(String fullName) {
    return fullName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }
}
