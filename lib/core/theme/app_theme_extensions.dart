import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.card,
    required this.border,
    required this.surfaceSecondary,
    required this.mutedText,
    required this.shadow,
    required this.heroGradient,
    required this.backgroundGradient,
    required this.glassBorder,
    required this.accentGreen,
    required this.accentPink,
    required this.accentOrange,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Glass fill (semi transparent white in light mode).
  final Color card;
  final Color border;
  final Color surfaceSecondary;
  final Color mutedText;
  final Color shadow;
  final Gradient heroGradient;

  /// Sky-blue page background.
  final Gradient backgroundGradient;
  final Color glassBorder;
  final Color accentGreen;
  final Color accentPink;
  final Color accentOrange;

  @override
  AppThemeColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? card,
    Color? border,
    Color? surfaceSecondary,
    Color? mutedText,
    Color? shadow,
    Gradient? heroGradient,
    Gradient? backgroundGradient,
    Color? glassBorder,
    Color? accentGreen,
    Color? accentPink,
    Color? accentOrange,
  }) {
    return AppThemeColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      card: card ?? this.card,
      border: border ?? this.border,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      mutedText: mutedText ?? this.mutedText,
      shadow: shadow ?? this.shadow,
      heroGradient: heroGradient ?? this.heroGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glassBorder: glassBorder ?? this.glassBorder,
      accentGreen: accentGreen ?? this.accentGreen,
      accentPink: accentPink ?? this.accentPink,
      accentOrange: accentOrange ?? this.accentOrange,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t)!,
      backgroundGradient: Gradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      accentPink: Color.lerp(accentPink, other.accentPink, t)!,
      accentOrange: Color.lerp(accentOrange, other.accentOrange, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
