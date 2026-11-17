import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'app_theme_extensions.dart';

ThemeData darkTheme([Color? accentColor]) {
  // Accent stays the user's chosen colour in both modes.
  final primary = accentColor ?? AppColors.darkPrimary;
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: Colors.white,
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
    card: const Color(0xB3182642), // dark glass ~70%
    border: AppColors.darkOutline,
    surfaceSecondary: const Color(0x99111B2E),
    mutedText: AppColors.darkTextSecondary,
    shadow: const Color(0x33000000),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, primary.withAlpha(200)],
    ),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.darkBgTop, AppColors.darkBgMid, AppColors.darkBgBottom],
      stops: [0.0, 0.45, 1.0],
    ),
    glassBorder: const Color(0x26FFFFFF),
    accentGreen: AppColors.darkSuccess,
    accentPink: AppColors.pink,
    accentOrange: AppColors.orange,
  );
  return AppTheme.build(scheme: scheme, colors: colors, scaffold: Colors.transparent);
}
