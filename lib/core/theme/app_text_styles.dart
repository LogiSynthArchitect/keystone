import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColors.white,
      );

  static TextStyle get h1 => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
        height: 1.3,
        color: AppColors.white,
      );

  static TextStyle get h2 => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        height: 1.3,
        color: AppColors.white,
      );

  static TextStyle get h3 => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.4,
        color: AppColors.white,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.5,
        color: AppColors.white,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.5,
        color: AppColors.white,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.5,
        color: AppColors.white,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColors.neutral400,
      );

  static TextStyle get captionMedium => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColors.neutral500,
      );

  static TextStyle get label => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        height: 1.2,
        color: AppColors.accent500,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        height: 1.2,
        color: AppColors.accent500,
      );

  static TextStyle get amount => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
        height: 1.2,
        color: AppColors.white,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  static TextStyle get amountSmall => const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.2,
        color: AppColors.white,
        fontFeatures: [FontFeature.tabularFigures()],
      );
}
