import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_dimensions.dart';
import 'app_text_styles.dart';
import 'app_theme_extensions.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build({
    required ColorScheme scheme,
    required AppThemeColors colors,
    required Color scaffold,
  }) {
    final text = AppTextStyles.textTheme(scheme.onSurface, colors.mutedText);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: c, width: w),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: text,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        hintStyle: text.bodyMedium?.copyWith(color: colors.mutedText),
        border: border(colors.border),
        enabledBorder: border(colors.border),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(colors.danger),
        focusedErrorBorder: border(colors.danger, 1.6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.card,
        indicatorColor: scheme.primary.withAlpha(32),
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
      dividerColor: colors.border,
    );
  }
}
