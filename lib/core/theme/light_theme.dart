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
    card: AppColors.white,
    border: AppColors.outline,
    surfaceSecondary: AppColors.surfaceSecondary,
    mutedText: AppColors.textSecondary,
    shadow: const Color(0x140D47A1),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, primary.withAlpha(200)],
    ),
  );
  return AppTheme.build(scheme: scheme, colors: colors, scaffold: AppColors.surface);
}