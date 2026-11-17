import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../providers/admin_providers.dart';

/// UI-side numbers for the admin charts. Everything is derived from the
/// orders / riders / exceptions that [AdminDashboardProvider] already streams
/// from Firebase. Nothing here talks to the backend.
class AdminStats {
  AdminStats(this.dash);

  final AdminDashboardProvider dash;

  List<DeliveryOrder> get orders => dash.orders;

  static DateTime _day(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static DateTime deliveredAt(DeliveryOrder o) =>
      o.proof?.submittedAt ?? o.deliveredAt ?? o.timeOf(OrderStatus.delivered) ?? o.createdAt;

  late final List<DeliveryOrder> delivered =
      orders.where((o) => o.status == OrderStatus.delivered).toList();

  /// Orders created per day, oldest -> newest.
  List<double> createdPerDay(int days) {
    final today = _day(DateTime.now());
    final out = List<double>.filled(days, 0);
    for (final o in orders) {
      final i = days - 1 - today.difference(_day(o.createdAt)).inDays;
      if (i >= 0 && i < days) out[i] += 1;
    }
    return out;
  }

  /// Orders delivered per day, oldest -> newest.
  List<double> deliveredPerDay(int days) {
    final today = _day(DateTime.now());
    final out = List<double>.filled(days, 0);
    for (final o in delivered) {
      final i = days - 1 - today.difference(_day(deliveredAt(o))).inDays;
      if (i >= 0 && i < days) out[i] += 1;
    }
    return out;
  }

  /// Delivered order value per day (Rs), oldest -> newest.
  List<double> revenuePerDay(int days) {
    final today = _day(DateTime.now());
    final out = List<double>.filled(days, 0);
    for (final o in delivered) {
      final i = days - 1 - today.difference(_day(deliveredAt(o))).inDays;
      if (i >= 0 && i < days) out[i] += o.amount.toDouble();
    }
    return out;
  }

  static List<String> dayLabels(int days) {
    final today = _day(DateTime.now());
    return [for (var i = 0; i < days; i++) '${today.subtract(Duration(days: days - 1 - i)).day}'];
  }

  static List<ChartBar> bars(List<double> values) {
    final today = _day(DateTime.now());
    return [
      for (var i = 0; i < values.length; i++)
        ChartBar(DateFormat('E').format(today.subtract(Duration(days: values.length - 1 - i))), values[i]),
    ];
  }

  int get inTransit => orders
      .where((o) => o.status == OrderStatus.pickedUp || o.status == OrderStatus.outForDelivery)
      .length;

  int get codCount => orders.where((o) => o.paymentType == PaymentType.cod).length;
  int get prepaidCount => orders.length - codCount;

  /// Orders grouped by delivery-window hour (waveform for the status cards).
  static List<double> hourBuckets(Iterable<DeliveryOrder> list, {int buckets = 6}) {
    final out = List<double>.filled(buckets, 0);
    for (final o in list) {
      out[(o.windowStart.hour * buckets ~/ 24).clamp(0, buckets - 1)] += 1;
    }
    return out;
  }

  Iterable<DeliveryOrder> byStatus(bool Function(OrderStatus) test) =>
      orders.where((o) => test(o.status));

  /// Rider with the most delivered orders (name + count).
  ({String name, int count})? get topRider {
    final counts = <String, int>{};
    for (final o in delivered) {
      final id = o.riderId;
      if (id == null || id.isEmpty) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final rider = dash.riders.where((r) => r.id == best.key);
    return (name: rider.isEmpty ? 'Rider' : rider.first.name, count: best.value);
  }

  /// Weekday with the most orders created (all time).
  ({String day, int count})? get busiestDay {
    if (orders.isEmpty) return null;
    final counts = List<int>.filled(8, 0);
    for (final o in orders) {
      counts[o.createdAt.toLocal().weekday] += 1;
    }
    var best = 1;
    for (var d = 2; d <= 7; d++) {
      if (counts[d] > counts[best]) best = d;
    }
    // 2024-01-01 is a Monday, so (best - 1) days later is the right weekday.
    final name = DateFormat('EEEE').format(DateTime(2024, 1, best));
    return (day: name, count: counts[best]);
  }

  /// Fastest delivery in minutes (pick-up/assign -> delivered).
  int? get fastestMinutes {
    int? best;
    for (final o in delivered) {
      final s = o.timeOf(OrderStatus.pickedUp) ?? o.timeOf(OrderStatus.assigned);
      final e = o.deliveredAt;
      if (s == null || e == null) continue;
      final m = e.difference(s).inMinutes;
      if (m < 0) continue;
      if (best == null || m < best) best = m;
    }
    return best;
  }

  /// Open + closed exceptions grouped by reason.
  List<DonutSlice> exceptionSlices(List<DeliveryException> list, List<Color> palette) {
    return [
      for (var i = 0; i < ExceptionReason.values.length; i++)
        DonutSlice(
          ExceptionReason.values[i].label,
          list.where((e) => e.reason == ExceptionReason.values[i]).length.toDouble(),
          palette[i % palette.length],
        ),
    ].where((s) => s.value > 0).toList();
  }
}
