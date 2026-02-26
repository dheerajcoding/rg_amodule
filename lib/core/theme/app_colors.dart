import 'package:flutter/material.dart';

/// Centralised colour palette for the entire app.
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFE85D2A);
  static const Color primaryLight = Color(0xFFFF8C5E);

  // Secondary / accent
  static const Color secondary = Color(0xFF2D4A8A);
  static const Color secondaryLight = Color(0xFF4A6FBE);

  // Neutrals
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFADB5BD);

  // Status
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // Dark theme variants
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);

  // Divider / border
  static const Color divider = Color(0xFFE9ECEF);
  static const Color border = Color(0xFFDEE2E6);

  // Overlay
  static const Color overlay = Color(0x80000000);
}
