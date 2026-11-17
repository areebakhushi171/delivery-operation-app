import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../utils/utils.dart';
import '../models/models.dart';

/// Shared Firestore plumbing so audit / history / notification / assignment
/// logic exists exactly once. Methods taking a [Transaction] must be called
/// AFTER all reads of that transaction.
class FirestoreHelpers {
  FirestoreHelpers(this.db);
  final FirebaseFirestore db;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get orders => db.collection('orders');
  CollectionReference<Map<String, dynamic>> get riders => db.collection('riders');
  CollectionReference<Map<String, dynamic>> get exceptions => db.collection('delivery_exceptions');
  CollectionReference<Map<String, dynamic>> get notifications => db.collection('notifications');

  void audit(Transaction tx, String action, String byUid, String target, [Map<String, dynamic>? data]) {
    tx.set(db.collection('audit_logs').doc(), {
      'action': action,
      'byUid': byUid,
      'target': target,
      'data': data,
      'at': FieldValue.serverTimestamp(),
    });
  }

  void history(Transaction tx, String orderId, StatusEntry e) {
    tx.set(db.collection('delivery_status_history').doc(), {
      ...e.toMap(),
      'orderId': orderId,
      'serverAt': FieldValue.serverTimestamp(),
    });
  }

  void notify(
    Transaction tx, {
    required String to,
    required NotificationType type,
    required String title,
    required String body,
    String? orderId,
  }) {
    final id = _uuid.v4();
    final n = AppNotification(
      id: id,
      recipientId: to,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      orderId: orderId,
    );
    tx.set(notifications.doc(id), {
      ...n.toMap(),
      'serverCreatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> nextStop(String riderId) async {
    final snap = await orders.where('riderId', isEqualTo: riderId).get();
    var max = 0;
    for (final d in snap.docs) {
      final o = DeliveryOrder.fromMap(d.data());
      if (!o.status.isClosed && (o.stopNumber ?? 0) > max) max = o.stopNumber!;
    }
    return max + 1;
  }

  void applyAssign(
    Transaction tx, {
    required DeliveryOrder order,
    required Rider rider,
    required int stop,
    required String byUid,
    String? note,
  }) {
    if (order.status == OrderStatus.delivered) {
      throw const AppException('Delivered orders cannot be reassigned.');
    }
    final km = (rider.hasLocation && order.hasLocation)
        ? LocationUtils.distanceKm(rider.lat!, rider.lng!, order.lat!, order.lng!)
        : order.distanceKm;
    final entry = StatusEntry(
      status: OrderStatus.assigned,
      at: DateTime.now(),
      byUid: byUid,
      note: note ?? 'Assigned to ${rider.name}',
    );
    tx.update(orders.doc(order.id), {
      'riderId': rider.id,
      'status': OrderStatus.assigned.name,
      'stopNumber': stop,
      'distanceKm': km,
      'etaMinutes': LocationUtils.etaMinutes(km),
      'history': FieldValue.arrayUnion([entry.toMap()]),
    });
    history(tx, order.id, entry);
    notify(tx,
        to: rider.id,
        type: NotificationType.assignment,
        title: 'New Assignment',
        body: 'Order ${order.id} assigned to you.',
        orderId: order.id);
    if (order.riderId != null && order.riderId != rider.id) {
      notify(tx,
          to: order.riderId!,
          type: NotificationType.routeChange,
          title: 'Route Update',
          body: 'Order ${order.id} was reassigned to another rider.',
          orderId: order.id);
    }
    audit(tx, 'order.assign', byUid, order.id, {'riderId': rider.id, 'previous': order.riderId});
  }

  void applyReschedule(
    Transaction tx, {
    required DeliveryOrder order,
    required DateTime start,
    required DateTime end,
    required String byUid,
  }) {
    if (order.status == OrderStatus.delivered) {
      throw const AppException('Delivered orders cannot be rescheduled.');
    }
    if (!end.isAfter(start)) throw const AppException('End time must be after start time.');
    final nextStatus = order.status == OrderStatus.failed
        ? (order.riderId != null ? OrderStatus.assigned : OrderStatus.unassigned)
        : order.status;
    final entry = StatusEntry(
      status: nextStatus,
      at: DateTime.now(),
      byUid: byUid,
      note: 'Rescheduled to ${DateTimeUtils.dateTime(start)}',
    );
    tx.update(orders.doc(order.id), {
      'windowStart': start.millisecondsSinceEpoch,
      'windowEnd': end.millisecondsSinceEpoch,
      'status': nextStatus.name,
      'history': FieldValue.arrayUnion([entry.toMap()]),
    });
    history(tx, order.id, entry);
    if (order.riderId != null) {
      notify(tx,
          to: order.riderId!,
          type: NotificationType.routeChange,
          title: 'Delivery rescheduled',
          body: 'Order ${order.id} moved to ${DateTimeUtils.dateTime(start)}.',
          orderId: order.id);
    }
    audit(tx, 'order.reschedule', byUid, order.id);
  }
}
