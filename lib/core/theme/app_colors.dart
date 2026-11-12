import 'package:flutter/material.dart';

/// Single source of truth for every colour used in the app.
class AppColors {
  AppColors._();

  // Brand / semantic (Deep Teal & Emerald SaaS Palette)
  static const primary = Color(0xFF0F766E); // Deep Teal
  static const primaryDark = Color(0xFF115E59);
  static const primaryLight = Color(0xFF14B8A6);
  static const surface = Color(0xFFF8FAFC); // Slate Canvas
  static const surfaceSecondary = Color(0xFFF1F5F9);
  static const white = Color(0xFFFFFFFF);
  static const success = Color(0xFF10B981); // Emerald Green
  static const warning = Color(0xFFF59E0B); // Amber Warning
  static const error = Color(0xFFEF4444); // Red Destructive
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const outline = Color(0xFFE2E8F0);

  // Dark equivalents
  static const darkSurface = Color(0xFF090D16);
  static const darkSurfaceSecondary = Color(0xFF111827);
  static const darkCard = Color(0xFF1F2937);
  static const darkPrimary = Color(0xFF2DD4BF);
  static const darkPrimaryContainer = Color(0xFF0F766E);
  static const darkSuccess = Color(0xFF34D399);
  static const darkWarning = Color(0xFFFBBF24);
  static const darkError = Color(0xFFF87171);
  static const darkText = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkOutline = Color(0xFF334155);

  // Map (mock) palette
  static const mapLight = Color(0xFFE2E8F0);
  static const mapDark = Color(0xFF1E293B);
}
