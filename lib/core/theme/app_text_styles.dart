import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Page Titles
  static TextStyle get h1 =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700);

  static TextStyle get h2 =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700);

  static TextStyle get h3 =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.normal);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal);

  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.normal);

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle get amount =>
      GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600);

  static TextStyle get sidebarMenu =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400);

  static TextStyle get sidebarSelected =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);
}
