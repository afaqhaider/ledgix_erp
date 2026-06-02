import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF0F172A); // Deep Dark Navy
  static const accentColor = Color(0xFF3B82F6); // Modern Blue Accent
  static const surfaceColor = Colors.white;
  static const backgroundColor = Color(0xFFF8FAFC);

  static const darkSurfaceColor = Color(0xFF1E293B);
  static const darkBackgroundColor = Color(0xFF020617);

  static final borderRadius = BorderRadius.circular(12);
  static const cardPadding = EdgeInsets.all(24);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      onSurface: const Color(0xFF1E293B),
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: primaryColor,
      elevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: primaryColor,
      selectedIconTheme: IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Colors.white60),
      selectedLabelTextStyle: TextStyle(color: Colors.white),
      unselectedLabelTextStyle: TextStyle(color: Colors.white60),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: accentColor,
      secondary: accentColor,
      surface: darkSurfaceColor,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: Color(0xFF334155)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurfaceColor,
      elevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: Color(0xFF334155))),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF020617),
      selectedIconTheme: IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Colors.white60),
      selectedLabelTextStyle: TextStyle(color: Colors.white),
      unselectedLabelTextStyle: TextStyle(color: Colors.white60),
    ),
  );
}
