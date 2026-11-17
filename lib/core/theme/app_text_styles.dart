import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography: Inter everywhere, sizes scaled with ScreenUtil.
class AppTextStyles {
  AppTextStyles._();

  static TextTheme textTheme(Color primary, Color secondary) {
    final base = GoogleFonts.interTextTheme();
    TextStyle s(TextStyle? b, double size, FontWeight w, Color c) =>
        (b ?? const TextStyle()).copyWith(fontSize: size.sp, fontWeight: w, color: c, height: 1.3);
    return base.copyWith(
      displayLarge: s(base.displayLarge, 44, FontWeight.w800, primary),
      displayMedium: s(base.displayMedium, 36, FontWeight.w800, primary),
      displaySmall: s(base.displaySmall, 28, FontWeight.w800, primary),
      headlineMedium: s(base.headlineMedium, 24, FontWeight.w700, primary),
      headlineSmall: s(base.headlineSmall, 20, FontWeight.w700, primary),
      titleLarge: s(base.titleLarge, 18, FontWeight.w700, primary),
      titleMedium: s(base.titleMedium, 16, FontWeight.w700, primary),
      titleSmall: s(base.titleSmall, 14, FontWeight.w600, primary),
      bodyLarge: s(base.bodyLarge, 16, FontWeight.w400, primary),
      bodyMedium: s(base.bodyMedium, 14, FontWeight.w400, primary),
      bodySmall: s(base.bodySmall, 12, FontWeight.w400, secondary),
      labelLarge: s(base.labelLarge, 14, FontWeight.w600, primary),
      labelMedium: s(base.labelMedium, 12, FontWeight.w600, secondary),
      labelSmall: s(base.labelSmall, 11, FontWeight.w600, secondary),
    );
  }
}
