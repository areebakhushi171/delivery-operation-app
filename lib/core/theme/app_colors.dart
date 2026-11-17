import 'package:flutter/material.dart';

/// Single source of truth for every colour used in the app.
/// Sky-blue glass palette: blue (primary) + light green, pink, orange accents.
class AppColors {
  AppColors._();

  // Brand / semantic
  static const primary = Color(0xFF3B82F6); // Blue
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFF93C5FD);
  static const surface = Color(0xFFEAF3FC); // Sky canvas
  static const surfaceSecondary = Color(0xFFF1F6FC);
  static const white = Color(0xFFFFFFFF);
  static const success = Color(0xFF16A34A); // Green
  static const warning = Color(0xFFF59E0B); // Amber
  static const error = Color(0xFFEF4444); // Red
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const outline = Color(0xFFE2E8F0);

  // Extra chart / accent colours
  static const lightGreen = Color(0xFF4ADE80);
  static const mint = Color(0xFF86EFAC);
  static const pink = Color(0xFFF472B6);
  static const orange = Color(0xFFFB923C);
  static const yellow = Color(0xFFFACC15);
  static const sky = Color(0xFF38BDF8);

  // Light background gradient (top -> middle -> bottom)
  static const bgTop = Color(0xFFB8D9F5);
  static const bgMid = Color(0xFFDCEBFA);
  static const bgBottom = Color(0xFFF4F7FB);

  // Dark equivalents
  static const darkSurface = Color(0xFF0B1220);
  static const darkSurfaceSecondary = Color(0xFF111B2E);
  static const darkCard = Color(0xFF16213A);
  static const darkPrimary = Color(0xFF60A5FA);
  static const darkPrimaryContainer = Color(0xFF1D4ED8);
  static const darkSuccess = Color(0xFF4ADE80);
  static const darkWarning = Color(0xFFFBBF24);
  static const darkError = Color(0xFFF87171);
  static const darkText = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkOutline = Color(0xFF2B3A55);
  static const darkBgTop = Color(0xFF0F1D38);
  static const darkBgMid = Color(0xFF0B1628);
  static const darkBgBottom = Color(0xFF080E1A);

  // Map (mock) palette
  static const mapLight = Color(0xFFDCEBFA);
  static const mapDark = Color(0xFF1E293B);
}
