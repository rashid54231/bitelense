import 'package:flutter/material.dart';

/// App color palette matching BiteLens design specifications:
/// Dark navy/near-black, vibrant green/teal gradients, translucent glass styling.
class AppColors {
  AppColors._();

  // Dark Theme Core
  static const Color darkBackground = Color(0xFF0B0F14);
  static const Color darkSurface = Color(0xFF131A22);
  static const Color darkSurfaceElevated = Color(0xFF1B2430);
  static const Color darkBorder = Color(0x14FFFFFF); // 8% white border

  // Light Theme Core
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0x1E000000); // subtle dark border

  // Accent Gradient Colors (Fresh Green -> Teal -> Lime)
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color primaryLime = Color(0xFF84CC16);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryGreen, primaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradientTri = LinearGradient(
    colors: [primaryGreen, primaryTeal, primaryLime],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0x28FFFFFF), Color(0x0CFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [Color(0xB3FFFFFF), Color(0x80FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Nutritional Macro Colors
  static const Color proteinColor = Color(0xFF38BDF8); // Cyan / Sky Blue
  static const Color carbsColor = Color(0xFFF59E0B);   // Amber / Orange
  static const Color fatColor = Color(0xFFF43F5E);     // Rose / Coral Red
  static const Color fiberColor = Color(0xFFA855F7);   // Purple / Lavender
  static const Color caloriesColor = Color(0xFF22C55E); // Green

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Text Colors (Dark mode)
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Text Colors (Light mode)
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
}
