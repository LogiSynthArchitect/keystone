import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColors.neutral900,
      );

  static TextStyle get h1 => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
        color: AppColors.neutral900,
      );

  static TextStyle get h2 => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: AppColors.neutral900,
      );

  static TextStyle get h3 => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: AppColors.neutral900,
      );

  static TextStyle get bodyLarge => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: AppColors.neutral900,
      );

  static TextStyle get body => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: AppColors.neutral900,
      );

  static TextStyle get bodyMedium => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.5,
        color: AppColors.neutral900,
      );

  static TextStyle get caption => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
        color: AppColors.neutral600,
      );

  static TextStyle get captionMedium => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
        color: AppColors.neutral700,
      );

  static TextStyle get label => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.2,
        color: AppColors.neutral900,
      );

  static TextStyle get labelSmall => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.2,
        color: AppColors.neutral900,
      );

  static TextStyle get amount => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.2,
        color: AppColors.neutral900,
      );

  static TextStyle get amountSmall => TextStyle(fontFamily: 'BarlowSemiCondensed',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.2,
        color: AppColors.neutral900,
      );
}
