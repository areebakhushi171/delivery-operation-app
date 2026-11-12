import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 8px base spacing unit and shared radii (all ScreenUtil-scaled).
class AppSpacing {
  AppSpacing._();
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
}

class AppRadius {
  AppRadius._();
  static double get input => 12.r;
  static double get card => 16.r;
  static double get sheet => 24.r;
  static double get chip => 20.r;
}
