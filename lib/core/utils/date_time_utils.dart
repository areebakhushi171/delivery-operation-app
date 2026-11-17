import 'package:intl/intl.dart';

enum DateRangeOption {
  today('Today', 1),
  last7('Last 7 days', 7),
  last30('Last 30 days', 30),
  all('All time', 0);

  const DateRangeOption(this.label, this.days);
  final String label;
  final int days;

  bool contains(DateTime d, DateTime now) {
    if (this == DateRangeOption.all) return true;
    final start = DateTimeUtils.startOfDay(now).subtract(Duration(days: days - 1));
    return !d.isBefore(start);
  }
}

class DateTimeUtils {
  DateTimeUtils._();

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String time(DateTime d) => DateFormat('h:mm a').format(d);
  static String date(DateTime d) => DateFormat('EEE, MMM d, y').format(d);
  static String shortDate(DateTime d) => DateFormat('MMM d').format(d);
  static String dateTime(DateTime d) => DateFormat('MMM d, h:mm a').format(d);

  static String window(DateTime start, DateTime end) => '${time(start)} - ${time(end)}';

  static String relative(DateTime d, [DateTime? now]) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
