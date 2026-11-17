import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'app_theme_extensions.dart';

ThemeData lightTheme([Color? accentColor]) {
  final primary = accentColor ?? AppColors.primary;
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: AppColors.white,
    secondary: primary,
    onSecondary: AppColors.white,
    error: AppColors.error,
    onError: AppColors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.outline,
    surfaceContainerHighest: AppColors.surfaceSecondary,
  );
  final colors = AppThemeColors(
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.error,
    info: primary,
    card: const Color(0xB8FFFFFF), // white ~72%
    border: const Color(0xFFD6E4F5),
    surfaceSecondary: const Color(0x99FFFFFF),
    mutedText: AppColors.textSecondary,
    shadow: const Color(0x14102A56),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, primary.withAlpha(200)],
    ),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
      stops: [0.0, 0.45, 1.0],
    ),
    glassBorder: const Color(0x99FFFFFF),
    accentGreen: AppColors.lightGreen,
    accentPink: AppColors.pink,
    accentOrange: AppColors.orange,
  );
  return AppTheme.build(scheme: scheme, colors: colors, scaffold: Colors.transparent);
}
