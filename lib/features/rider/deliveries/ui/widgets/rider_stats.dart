import 'package:intl/intl.dart';

import '../../../../../core/core.dart';
import '../../providers/rider_orders_provider.dart';

/// UI-side numbers for the rider charts. Everything is derived from the
/// orders the existing [RiderOrdersProvider] already streams from Firebase.
/// Nothing here talks to the backend.
class RiderStats {
  RiderStats(this.p);

  final RiderOrdersProvider p;

  late final List<DeliveryOrder> delivered =
      p.history(failedTab: false, range: DateRangeOption.last30);
  late final List<DeliveryOrder> failed =
      p.history(failedTab: true, range: DateRangeOption.last30);

  static DateTime closedAt(DeliveryOrder o) => o.deliveredAt ?? o.failedAt ?? o.windowEnd;

  /// Orders closed per day, oldest -> newest, [days] entries.
  static List<double> dailyCounts(Iterable<DeliveryOrder> list, int days) {
    final today = DateTimeUtils.startOfDay(DateTime.now());
    final out = List<double>.filled(days, 0);
    for (final o in list) {
      final d = DateTimeUtils.startOfDay(closedAt(o));
      final idx = days - 1 - today.difference(d).inDays;
      if (idx >= 0 && idx < days) out[idx] += 1;
    }
    return out;
  }

  /// x labels (day of month) matching [dailyCounts].
  static List<String> dayLabels(int days) {
    final today = DateTimeUtils.startOfDay(DateTime.now());
    return [
      for (var i = 0; i < days; i++) '${today.subtract(Duration(days: days - 1 - i)).day}',
    ];
  }

  /// Last 7 days as bars (Mon, Tue ...).
  static List<ChartBar> weekBars(Iterable<DeliveryOrder> list) {
    final today = DateTimeUtils.startOfDay(DateTime.now());
    final counts = dailyCounts(list, 7);
    return [
      for (var i = 0; i < 7; i++)
        ChartBar(DateFormat('E').format(today.subtract(Duration(days: 6 - i))), counts[i]),
    ];
  }

  /// Orders grouped by the hour of their delivery window (for today's cards).
  static List<double> hourBuckets(Iterable<DeliveryOrder> list, {int buckets = 6}) {
    final out = List<double>.filled(buckets, 0);
    for (final o in list) {
      final i = (o.windowStart.hour * buckets ~/ 24).clamp(0, buckets - 1);
      out[i] += 1;
    }
    return out;
  }

  int get pendingToday => p.today
      .where((o) => o.status == OrderStatus.assigned || o.status == OrderStatus.unassigned)
      .length;
  int get inTransitToday => p.today
      .where((o) => o.status == OrderStatus.pickedUp || o.status == OrderStatus.outForDelivery)
      .length;

  /// Minutes from pick-up (or assignment) to delivery, last 30 days.
  late final List<int> durations = [
    for (final o in delivered)
      if (_minutes(o) != null) _minutes(o)!,
  ];

  static int? _minutes(DeliveryOrder o) {
    final s = o.timeOf(OrderStatus.pickedUp) ?? o.timeOf(OrderStatus.assigned);
    final e = o.deliveredAt;
    if (s == null || e == null) return null;
    final m = e.difference(s).inMinutes;
    return m >= 0 ? m : null;
  }

  int? get fastest => durations.isEmpty ? null : durations.reduce((a, b) => a < b ? a : b);
  int? get longest => durations.isEmpty ? null : durations.reduce((a, b) => a > b ? a : b);

  static String minutesText(int m) => m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '$m min';
}
