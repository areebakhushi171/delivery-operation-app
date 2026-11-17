import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 8px base spacing unit and shared radii (all ScreenUtil-scaled).
class AppSpacing {
  AppSpacing._();
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;

  /// Screen side padding and gap between cards (glass layout).
  static double get screen => 20.w;
  static double get gap => 16.w;
}

class AppRadius {
  AppRadius._();
  static double get input => 16.r;
  static double get card => 24.r;
  static double get sheet => 28.r;
  static double get chip => 20.r;
}
