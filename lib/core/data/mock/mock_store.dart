import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../utils/utils.dart';
import '../models/models.dart';
import 'mock_seed.dart';

/// Tiny reactive value holder: new listeners get the current value first.
class Feed<T> {
  Feed(this._value);
  T _value;
  final StreamController<T> _controller = StreamController<T>.broadcast();

  T get value => _value;
  set value(T v) {
    _value = v;
    _controller.add(v);
  }

  Stream<T> watch() {
    late StreamController<T> out;
    StreamSubscription<T>? sub;
    out = StreamController<T>(
      onListen: () {
        out.add(_value);
        sub = _controller.stream.listen(out.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }
}

/// In-memory "backend" shared by EVERY mock repository, so Rider and Admin
/// always see the same canonical documents. Business rules live here so the
/// individual mock repositories stay thin.
class MockStore {
  MockStore._() {
    final seed = MockSeed.build(DateTime.now());
    orders.value = seed.orders;
    riders.value = seed.riders;
    exceptions.value = seed.exceptions;
    notifications.value = seed.notifications;
  }

  static final MockStore instance = MockStore._();
  static const _uuid = Uuid();

  final Feed<List<DeliveryOrder>> orders = Feed(const []);
  final Feed<List<Rider>> riders = Feed(const []);
  final Feed<List<DeliveryException>> exceptions = Feed(const []);
  final Feed<List<AppNotification>> notifications = Feed(const []);
  final List<Map<String, dynamic>> auditLogs = [];
  int _orderCounter = 9831;

  // ---------- lookups ----------
  DeliveryOrder? orderById(String id) => orders.value.where((o) => o.id == id).firstOrNull;
  Rider? riderById(String id) => riders.value.where((r) => r.id == id).firstOrNull;
  DeliveryException? exceptionById(String id) =>
      exceptions.value.where((e) => e.id == id).firstOrNull;

  DeliveryOrder requireOrder(String id) =>
      orderById(id) ?? (throw const AppException('Order not found.'));
  Rider requireRider(String id) =>
      riderById(id) ?? (throw const AppException('Rider not found.'));

  // ---------- writes ----------
  String nextOrderId() => 'PK-${++_orderCounter}';

  void putOrder(DeliveryOrder o) =>
      orders.value = [for (final e in orders.value) e.id == o.id ? o : e];
  void addOrder(DeliveryOrder o) => orders.value = [o, ...orders.value];
  void putRider(Rider r) => riders.value = [for (final e in riders.value) e.id == r.id ? r : e];
  void putException(DeliveryException x) =>
      exceptions.value = [for (final e in exceptions.value) e.id == x.id ? x : e];
  void addException(DeliveryException x) => exceptions.value = [x, ...exceptions.value];

  void notify({
    required String to,
    required NotificationType type,
    required String title,
    required String body,
    String? orderId,
  }) {
    notifications.value = [
      AppNotification(
        id: _uuid.v4(),
        recipientId: to,
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        orderId: orderId,
      ),
      ...notifications.value,
    ];
  }

  void audit(String action, String byUid, String target, [Map<String, dynamic>? data]) {
    auditLogs.add({
      'action': action,
      'byUid': byUid,
      'target': target,
      'at': DateTime.now().millisecondsSinceEpoch,
      if (data != null) 'data': data,
    });
  }

  int nextStopFor(String riderId) {
    var max = 0;
    for (final o in orders.value) {
      if (o.riderId == riderId && !o.status.isClosed && (o.stopNumber ?? 0) > max) {
        max = o.stopNumber!;
      }
    }
    return max + 1;
  }

  /// Keeps the rider's "current delivery" telemetry in step with the orders.
  void refreshRider(String riderId) {
    final rider = riderById(riderId);
    if (rider == null) return;
    final mine = orders.value.where((o) => o.riderId == riderId && o.status.isActive).toList()
      ..sort((a, b) => (a.stopNumber ?? 999).compareTo(b.stopNumber ?? 999));
    DeliveryOrder? current;
    for (final o in mine) {
      if (o.status == OrderStatus.outForDelivery) {
        current = o;
        break;
      }
    }
    current ??= mine.isEmpty ? null : mine.first;
    putRider(
      rider.copyWith(
        currentOrderId: current?.id,
        currentStop: current?.stopNumber,
        etaMinutes: current?.etaMinutes,
        clearCurrent: current == null,
      ),
    );
  }

  // ---------- shared business rules ----------
  void assignOrder({
    required String orderId,
    required String riderId,
    required String byUid,
    String? note,
  }) {
    final o = requireOrder(orderId);
    if (o.status == OrderStatus.delivered) {
      throw const AppException('Delivered orders cannot be reassigned.');
    }
    final rider = requireRider(riderId);
    final previous = o.riderId;
    final km = (rider.hasLocation && o.hasLocation)
        ? LocationUtils.distanceKm(rider.lat!, rider.lng!, o.lat!, o.lng!)
        : o.distanceKm;
    putOrder(
      o.copyWith(
        riderId: riderId,
        status: OrderStatus.assigned,
        stopNumber: nextStopFor(riderId),
        distanceKm: km,
        etaMinutes: LocationUtils.etaMinutes(km),
        history: [
          ...o.history,
          StatusEntry(
            status: OrderStatus.assigned,
            at: DateTime.now(),
            byUid: byUid,
            note: note ?? 'Assigned to ${rider.name}',
          ),
        ],
      ),
    );
    notify(
      to: riderId,
      type: NotificationType.assignment,
      title: 'New Assignment',
      body: 'Order $orderId assigned to you.',
      orderId: orderId,
    );
    if (previous != null && previous != riderId) {
      notify(
        to: previous,
        type: NotificationType.routeChange,
        title: 'Route Update',
        body: 'Order $orderId was reassigned to another rider.',
        orderId: orderId,
      );
      refreshRider(previous);
    }
    refreshRider(riderId);
    audit('order.assign', byUid, orderId, {'riderId': riderId, 'previous': previous});
  }

  void rescheduleOrder({
    required String orderId,
    required DateTime start,
    required DateTime end,
    required String byUid,
  }) {
    final o = requireOrder(orderId);
    if (o.status == OrderStatus.delivered) {
      throw const AppException('Delivered orders cannot be rescheduled.');
    }
    if (!end.isAfter(start)) throw const AppException('End time must be after start time.');
    final nextStatus = o.status == OrderStatus.failed
        ? (o.riderId != null ? OrderStatus.assigned : OrderStatus.unassigned)
        : o.status;
    putOrder(
      o.copyWith(
        windowStart: start,
        windowEnd: end,
        status: nextStatus,
        history: [
          ...o.history,
          StatusEntry(
            status: nextStatus,
            at: DateTime.now(),
            byUid: byUid,
            note: 'Rescheduled to ${DateTimeUtils.dateTime(start)}',
          ),
        ],
      ),
    );
    if (o.riderId != null) {
      notify(
        to: o.riderId!,
        type: NotificationType.routeChange,
        title: 'Delivery rescheduled',
        body: 'Order $orderId moved to ${DateTimeUtils.dateTime(start)}.',
        orderId: orderId,
      );
      refreshRider(o.riderId!);
    }
    audit('order.reschedule', byUid, orderId);
  }
}
