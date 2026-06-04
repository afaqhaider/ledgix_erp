import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';

class AppTheme {
  static final borderRadius = BorderRadius.circular(AppSpacing.borderRadius);
  static final TextTheme _lightTextTheme =
      GoogleFonts.interTextTheme(ThemeData.light().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
            displayMedium: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
            displaySmall: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
            headlineLarge: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            headlineMedium: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            headlineSmall: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            titleSmall: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: GoogleFonts.inter(fontSize: 14),
            bodyMedium: GoogleFonts.inter(fontSize: 13),
            bodySmall: GoogleFonts.inter(fontSize: 11),
            labelLarge: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            labelMedium: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            labelSmall: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          )
          .apply(
            bodyColor: AppColors.lightTextPrimary,
            displayColor: AppColors.lightTextPrimary,
          );

  static final TextTheme _darkTextTheme =
      GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
            displayMedium: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
            displaySmall: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
            headlineLarge: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            headlineMedium: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            headlineSmall: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            titleSmall: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: GoogleFonts.inter(fontSize: 14),
            bodyMedium: GoogleFonts.inter(fontSize: 13),
            bodySmall: GoogleFonts.inter(fontSize: 11),
            labelLarge: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            labelMedium: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            labelSmall: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          )
          .apply(
            bodyColor: AppColors.darkTextPrimary,
            displayColor: AppColors.darkTextPrimary,
          );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.error,
      outlineVariant: AppColors.lightBorder,
    ),
    textTheme: _lightTextTheme,
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.lightBorder),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.lightTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextSecondary,
      ),
      dataTextStyle: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.lightTextPrimary,
      ),
      horizontalMargin: 16,
      columnSpacing: 18,
      headingRowColor: WidgetStateProperty.all(AppColors.lightBackground),
      dataRowMinHeight: 34,
      dataRowMaxHeight: 38,
    ),
    listTileTheme: const ListTileThemeData(
      dense: true,
      minVerticalPadding: 4,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      titleTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 11,
        color: AppColors.lightTextSecondary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        padding: const EdgeInsets.all(7),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.lightTextSecondary,
      ),
      hintStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.lightTextSecondary,
      ),
      prefixIconColor: AppColors.lightTextSecondary,
      suffixIconColor: AppColors.lightTextSecondary,
      border: OutlineInputBorder(borderRadius: borderRadius),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.error,
      outlineVariant: AppColors.darkBorder,
    ),
    textTheme: _darkTextTheme,
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.darkTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      shape: const Border(bottom: BorderSide(color: AppColors.darkBorder)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextSecondary,
      ),
      dataTextStyle: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.darkTextPrimary,
      ),
      horizontalMargin: 16,
      columnSpacing: 18,
      headingRowColor: WidgetStateProperty.all(AppColors.darkSurface),
      dataRowMinHeight: 34,
      dataRowMaxHeight: 38,
    ),
    listTileTheme: const ListTileThemeData(
      dense: true,
      minVerticalPadding: 4,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      titleTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 11,
        color: AppColors.darkTextSecondary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        padding: const EdgeInsets.all(7),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.darkTextSecondary,
      ),
      prefixIconColor: AppColors.darkTextSecondary,
      suffixIconColor: AppColors.darkTextSecondary,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.darkTextSecondary,
      ),
    ),
  );
}
