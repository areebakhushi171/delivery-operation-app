import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static final NumberFormat _fmt = NumberFormat('#,##0');

  static String rs(num value) => 'Rs. ${_fmt.format(value)}';

  /// Compact form for KPI tiles, e.g. Rs. 12.5K.
  static String rsCompact(num value) {
    if (value >= 1000000) return 'Rs. ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 10000) return 'Rs. ${(value / 1000).toStringAsFixed(1)}K';
    return rs(value);
  }
}
