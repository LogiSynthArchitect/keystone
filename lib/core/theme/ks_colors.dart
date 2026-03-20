import 'package:flutter/material.dart';

/// Adaptive color palette for Keystone.
/// Dark  = the existing navy-gold industrial palette.
/// Light = white-card, navy-text inversion of the same palette.
///
/// Access via: `context.ksc.primary900` etc.
class KsColors extends ThemeExtension<KsColors> {
  const KsColors({
    required this.primary900,
    required this.primary800,
    required this.primary700,
    required this.primary600,
    required this.primary500,
    required this.primary400,
    required this.primary100,
    required this.primary050,
    required this.accent600,
    required this.accent500,
    required this.accent400,
    required this.accent100,
    required this.neutral900,
    required this.neutral800,
    required this.neutral700,
    required this.neutral600,
    required this.neutral500,
    required this.neutral400,
    required this.neutral300,
    required this.neutral200,
    required this.neutral100,
    required this.neutral050,
    required this.white,
    required this.success600,
    required this.success500,
    required this.success100,
    required this.warning600,
    required this.warning500,
    required this.warning100,
    required this.error600,
    required this.error500,
    required this.error100,
    required this.offline,
    required this.offlineBg,
  });

  final Color primary900;
  final Color primary800;
  final Color primary700;
  final Color primary600;
  final Color primary500;
  final Color primary400;
  final Color primary100;
  final Color primary050;

  final Color accent600;
  final Color accent500;
  final Color accent400;
  final Color accent100;

  final Color neutral900;
  final Color neutral800;
  final Color neutral700;
  final Color neutral600;
  final Color neutral500;
  final Color neutral400;
  final Color neutral300;
  final Color neutral200;
  final Color neutral100;
  final Color neutral050;
  final Color white;

  final Color success600;
  final Color success500;
  final Color success100;
  final Color warning600;
  final Color warning500;
  final Color warning100;
  final Color error600;
  final Color error500;
  final Color error100;

  final Color offline;
  final Color offlineBg;

  // ─── DARK (existing palette) ─────────────────────────────────────────────
  static const KsColors dark = KsColors(
    primary900: Color(0xFF0A1628),
    primary800: Color(0xFF0F2144),
    primary700: Color(0xFF163060),
    primary600: Color(0xFF1E3F7A),
    primary500: Color(0xFF2952A3),
    primary400: Color(0xFF4A6EC4),
    primary100: Color(0xFFE8EDF7),
    primary050: Color(0xFFF3F6FC),

    accent600: Color(0xFFB8860B),
    accent500: Color(0xFFD4A017),
    accent400: Color(0xFFE8B84B),
    accent100: Color(0xFFFDF3D0),

    neutral900: Color(0xFF1A1A1A),
    neutral800: Color(0xFF2D2D2D),
    neutral700: Color(0xFF404040),
    neutral600: Color(0xFF5C5C5C),
    neutral500: Color(0xFF737373),
    neutral400: Color(0xFF9E9E9E),
    neutral300: Color(0xFFBDBDBD),
    neutral200: Color(0xFFE0E0E0),
    neutral100: Color(0xFFF5F5F5),
    neutral050: Color(0xFFFAFAFA),
    white:      Color(0xFFFFFFFF),

    success600: Color(0xFF1B6B3A),
    success500: Color(0xFF2E7D32),
    success100: Color(0xFFE8F5E9),
    warning600: Color(0xFFE65100),
    warning500: Color(0xFFF57C00),
    warning100: Color(0xFFFFF3E0),
    error600:   Color(0xFFB71C1C),
    error500:   Color(0xFFC62828),
    error100:   Color(0xFFFFEBEE),

    offline:   Color(0xFF9E9E9E),
    offlineBg: Color(0xFFF5F5F5),
  );

  // ─── LIGHT ───────────────────────────────────────────────────────────────
  static const KsColors light = KsColors(
    // Page + surface hierarchy inverted: dark navy → light blue-white
    primary900: Color(0xFFF4F7FF), // page background
    primary800: Color(0xFFFFFFFF), // card / surface
    primary700: Color(0xFFDCE6F5), // borders / dividers
    primary600: Color(0xFFB0C4DE), // active borders
    primary500: Color(0xFF2952A3), // interactive (same blue)
    primary400: Color(0xFF4A6EC4), // lighter interactive (same)
    primary100: Color(0xFFE8EDF7), // same
    primary050: Color(0xFFF3F6FC), // same

    accent600: Color(0xFFB8860B),
    accent500: Color(0xFFD4A017), // gold stays gold
    accent400: Color(0xFFE8B84B),
    accent100: Color(0xFFFDF3D0),

    neutral900: Color(0xFF1A1A1A),
    neutral800: Color(0xFF2D2D2D),
    neutral700: Color(0xFF404040),
    // Darker neutrals for legibility on white backgrounds
    neutral600: Color(0xFF374151),
    neutral500: Color(0xFF4B5563),
    neutral400: Color(0xFF6B7280),
    neutral300: Color(0xFF9CA3AF),
    neutral200: Color(0xFFE5E7EB),
    neutral100: Color(0xFFF9FAFB),
    neutral050: Color(0xFFFFFFFF),
    white:      Color(0xFF0A1628), // "white" = primary text → dark navy in light mode

    success600: Color(0xFF1B6B3A),
    success500: Color(0xFF2E7D32),
    success100: Color(0xFFE8F5E9),
    warning600: Color(0xFFE65100),
    warning500: Color(0xFFF57C00),
    warning100: Color(0xFFFFF3E0),
    error600:   Color(0xFFB71C1C),
    error500:   Color(0xFFC62828),
    error100:   Color(0xFFFFEBEE),

    offline:   Color(0xFF9CA3AF),
    offlineBg: Color(0xFFF3F4F6),
  );

  // ─── ThemeExtension contract ──────────────────────────────────────────────
  @override
  KsColors copyWith({
    Color? primary900, Color? primary800, Color? primary700, Color? primary600,
    Color? primary500, Color? primary400, Color? primary100, Color? primary050,
    Color? accent600, Color? accent500, Color? accent400, Color? accent100,
    Color? neutral900, Color? neutral800, Color? neutral700, Color? neutral600,
    Color? neutral500, Color? neutral400, Color? neutral300, Color? neutral200,
    Color? neutral100, Color? neutral050, Color? white,
    Color? success600, Color? success500, Color? success100,
    Color? warning600, Color? warning500, Color? warning100,
    Color? error600, Color? error500, Color? error100,
    Color? offline, Color? offlineBg,
  }) => KsColors(
    primary900: primary900 ?? this.primary900,
    primary800: primary800 ?? this.primary800,
    primary700: primary700 ?? this.primary700,
    primary600: primary600 ?? this.primary600,
    primary500: primary500 ?? this.primary500,
    primary400: primary400 ?? this.primary400,
    primary100: primary100 ?? this.primary100,
    primary050: primary050 ?? this.primary050,
    accent600: accent600 ?? this.accent600,
    accent500: accent500 ?? this.accent500,
    accent400: accent400 ?? this.accent400,
    accent100: accent100 ?? this.accent100,
    neutral900: neutral900 ?? this.neutral900,
    neutral800: neutral800 ?? this.neutral800,
    neutral700: neutral700 ?? this.neutral700,
    neutral600: neutral600 ?? this.neutral600,
    neutral500: neutral500 ?? this.neutral500,
    neutral400: neutral400 ?? this.neutral400,
    neutral300: neutral300 ?? this.neutral300,
    neutral200: neutral200 ?? this.neutral200,
    neutral100: neutral100 ?? this.neutral100,
    neutral050: neutral050 ?? this.neutral050,
    white: white ?? this.white,
    success600: success600 ?? this.success600,
    success500: success500 ?? this.success500,
    success100: success100 ?? this.success100,
    warning600: warning600 ?? this.warning600,
    warning500: warning500 ?? this.warning500,
    warning100: warning100 ?? this.warning100,
    error600: error600 ?? this.error600,
    error500: error500 ?? this.error500,
    error100: error100 ?? this.error100,
    offline: offline ?? this.offline,
    offlineBg: offlineBg ?? this.offlineBg,
  );

  @override
  KsColors lerp(KsColors? other, double t) {
    if (other == null) return this;
    return KsColors(
      primary900: Color.lerp(primary900, other.primary900, t)!,
      primary800: Color.lerp(primary800, other.primary800, t)!,
      primary700: Color.lerp(primary700, other.primary700, t)!,
      primary600: Color.lerp(primary600, other.primary600, t)!,
      primary500: Color.lerp(primary500, other.primary500, t)!,
      primary400: Color.lerp(primary400, other.primary400, t)!,
      primary100: Color.lerp(primary100, other.primary100, t)!,
      primary050: Color.lerp(primary050, other.primary050, t)!,
      accent600: Color.lerp(accent600, other.accent600, t)!,
      accent500: Color.lerp(accent500, other.accent500, t)!,
      accent400: Color.lerp(accent400, other.accent400, t)!,
      accent100: Color.lerp(accent100, other.accent100, t)!,
      neutral900: Color.lerp(neutral900, other.neutral900, t)!,
      neutral800: Color.lerp(neutral800, other.neutral800, t)!,
      neutral700: Color.lerp(neutral700, other.neutral700, t)!,
      neutral600: Color.lerp(neutral600, other.neutral600, t)!,
      neutral500: Color.lerp(neutral500, other.neutral500, t)!,
      neutral400: Color.lerp(neutral400, other.neutral400, t)!,
      neutral300: Color.lerp(neutral300, other.neutral300, t)!,
      neutral200: Color.lerp(neutral200, other.neutral200, t)!,
      neutral100: Color.lerp(neutral100, other.neutral100, t)!,
      neutral050: Color.lerp(neutral050, other.neutral050, t)!,
      white: Color.lerp(white, other.white, t)!,
      success600: Color.lerp(success600, other.success600, t)!,
      success500: Color.lerp(success500, other.success500, t)!,
      success100: Color.lerp(success100, other.success100, t)!,
      warning600: Color.lerp(warning600, other.warning600, t)!,
      warning500: Color.lerp(warning500, other.warning500, t)!,
      warning100: Color.lerp(warning100, other.warning100, t)!,
      error600: Color.lerp(error600, other.error600, t)!,
      error500: Color.lerp(error500, other.error500, t)!,
      error100: Color.lerp(error100, other.error100, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      offlineBg: Color.lerp(offlineBg, other.offlineBg, t)!,
    );
  }
}

/// Shortcut: `context.ksc.primary900`
extension KsColorsContext on BuildContext {
  KsColors get ksc => Theme.of(this).extension<KsColors>()!;
}
