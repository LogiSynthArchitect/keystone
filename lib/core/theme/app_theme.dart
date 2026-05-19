import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'ks_colors.dart';

ThemeData buildDarkAppTheme() {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'BarlowSemiCondensed',
  );

  return baseTheme.copyWith(
    extensions: const [KsColors.dark],
    scaffoldBackgroundColor: AppColors.primary900,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent500,
      brightness: Brightness.dark,
      primary: AppColors.accent500,
      onPrimary: AppColors.primary900,
      secondary: AppColors.primary400,
      onSecondary: AppColors.white,
      surface: AppColors.primary800,
      onSurface: AppColors.white,
      surfaceContainerHighest: AppColors.primary700,
      error: AppColors.error500,
      onError: AppColors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary900,
      foregroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      toolbarHeight: AppSpacing.appBarHeight,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.primary900,
      selectedItemColor: AppColors.accent500,
      unselectedItemColor: AppColors.neutral500,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      color: AppColors.primary800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.primary700),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.primary800,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent500, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error500, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.neutral600),
      labelStyle: const TextStyle(color: AppColors.neutral400),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent500,
        foregroundColor: AppColors.primary900,
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent500,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.accent500),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.primary700,
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.accent500 : AppColors.neutral500),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.accent500.withValues(alpha: 0.3)
              : AppColors.primary700),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent500,
      foregroundColor: AppColors.primary900,
      elevation: 4,
      highlightElevation: 8,
      shape: CircleBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.primary800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primary700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primary800,
      contentTextStyle: const TextStyle(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent500,
      linearTrackColor: AppColors.primary700,
    ),
  );
}

ThemeData buildLightAppTheme() {
  const c = KsColors.light;

  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'BarlowSemiCondensed',
  );

  return baseTheme.copyWith(
    extensions: const [KsColors.light],
    scaffoldBackgroundColor: c.primary900,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent500,
      brightness: Brightness.light,
      primary: c.accent500,
      onPrimary: c.primary800,
      secondary: c.primary600,
      onSecondary: c.white,
      surface: c.primary800,
      onSurface: c.white,
      surfaceContainerHighest: c.primary700,
      error: c.error500,
      onError: c.primary800,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.primary900,
      foregroundColor: c.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      toolbarHeight: AppSpacing.appBarHeight,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.primary900,
      selectedItemColor: c.accent500,
      unselectedItemColor: c.neutral500,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      color: c.primary800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: c.primary700),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.primary800,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.primary700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.primary700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.accent500, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.error500, width: 1.5),
      ),
      hintStyle: TextStyle(color: c.neutral600),
      labelStyle: TextStyle(color: c.neutral400),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.accent500,
        foregroundColor: c.primary900,
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent500,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: c.accent500),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: c.primary700,
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? c.accent500 : c.neutral500),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? c.accent500.withValues(alpha: 0.3)
              : c.primary700),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent500,
      foregroundColor: c.primary900,
      elevation: 4,
      highlightElevation: 8,
      shape: const CircleBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.primary800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.primary700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.primary800,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent500,
      linearTrackColor: c.primary700,
    ),
  );
}

ThemeData buildAppTheme() => buildDarkAppTheme();
