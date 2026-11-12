import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'app_theme_extensions.dart';

ThemeData darkTheme([Color? accentColor]) {
  // Primary dono modes mein wahi rehta hai (user ka chuna hua accent)
  final primary = accentColor ?? AppColors.darkPrimary;
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: Colors.white, // primary buttons par text saaf nazar aaye
    secondary: primary,
    onSecondary: Colors.white,
    error: AppColors.darkError,
    onError: AppColors.darkSurface,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkOutline,
    surfaceContainerHighest: AppColors.darkSurfaceSecondary,
  );
  final colors = AppThemeColors(
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    danger: AppColors.darkError,
    info: primary,
    card: AppColors.darkCard,
    border: AppColors.darkOutline,
    surfaceSecondary: AppColors.darkSurfaceSecondary,
    mutedText: AppColors.darkTextSecondary,
    shadow: const Color(0x33000000),
    // Light mode jaisa hi gradient: accent color se bana, teal nahi
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, primary.withAlpha(200)],
    ),
  );
  return AppTheme.build(scheme: scheme, colors: colors, scaffold: AppColors.darkSurface);
}