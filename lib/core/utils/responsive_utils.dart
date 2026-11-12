import 'package:flutter/material.dart';

class ResponsiveUtils {
  ResponsiveUtils._();

  static const double compactMax = 600;
  static const double railMin = 840;

  static bool isCompact(BuildContext c) => MediaQuery.sizeOf(c).width < compactMax;
  static bool useNavigationRail(BuildContext c) => MediaQuery.sizeOf(c).width >= railMin;
  static int gridColumns(BuildContext c, {int compact = 2, int wide = 4}) =>
      MediaQuery.sizeOf(c).width >= railMin ? wide : compact;
}
