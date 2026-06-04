import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';

class AppTheme {
  static final borderRadius = BorderRadius.circular(AppSpacing.borderRadius);
  static const darkSurfaceVariant = AppColors.surfaceVariantDark;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onSurfaceLight,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.borderLight),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: AppColors.borderLight)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      brightness: Brightness.dark,
    ).copyWith(
      background: AppColors.backgroundDark,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: const TextStyle(color: Colors.white70),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: AppColors.borderDark),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: AppColors.borderDark),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: AppColors.surfaceVariantDark)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
    ),
  );
}
