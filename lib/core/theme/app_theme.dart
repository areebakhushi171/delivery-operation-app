import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_background.dart';
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
    final isLight = scheme.brightness == Brightness.light;
    final text = AppTextStyles.textTheme(scheme.onSurface, colors.mutedText);
    final solid = isLight ? Colors.white : const Color(0xFF16213A);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: c, width: w),
        );
    final pill = StadiumBorder(side: BorderSide(color: colors.glassBorder));

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      // Transparent: the gradient comes from AppBackground (app root + transitions).
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: solid,
      textTheme: text,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: GlassPageTransitionsBuilder(),
        TargetPlatform.iOS: GlassPageTransitionsBuilder(),
        TargetPlatform.macOS: GlassPageTransitionsBuilder(),
        TargetPlatform.windows: GlassPageTransitionsBuilder(),
        TargetPlatform.linux: GlassPageTransitionsBuilder(),
        TargetPlatform.fuchsia: GlassPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
        hintStyle: text.bodyMedium?.copyWith(color: colors.mutedText),
        border: border(colors.glassBorder),
        enabledBorder: border(colors.glassBorder),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(colors.danger),
        focusedErrorBorder: border(colors.danger, 1.6),
        disabledBorder: border(colors.glassBorder),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: colors.card,
          shape: const StadiumBorder(),
          side: BorderSide(color: colors.glassBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary, textStyle: text.labelLarge),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.card,
        selectedColor: scheme.primary,
        disabledColor: colors.card,
        side: BorderSide(color: colors.glassBorder),
        shape: const StadiumBorder(),
        showCheckmark: false,
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: Colors.white),
        padding: EdgeInsets.symmetric(horizontal: 6.w),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(pill),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? scheme.primary : colors.card,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: colors.glassBorder)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : colors.mutedText.withAlpha(90),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: colors.surfaceSecondary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: solid,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: solid,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: solid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: solid,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(solid)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primary.withAlpha(32),
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? const Color(0xFF1F2A44) : const Color(0xFF22304F),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
      dividerColor: colors.border,
      dividerTheme: DividerThemeData(color: colors.border.withAlpha(140), space: 1),
    );
  }
}
