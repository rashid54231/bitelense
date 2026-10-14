import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography definitions using Poppins for headings and Inter for body copy.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge(BuildContext context) => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle displayMedium(BuildContext context) => GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  static TextStyle titleLarge(BuildContext context) => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle titleMedium(BuildContext context) => GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      );

  static TextStyle titleSmall(BuildContext context) => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  static TextStyle labelLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle labelSmall(BuildContext context) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  static TextStyle calorieCounter(BuildContext context) => GoogleFonts.poppins(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      );
}
