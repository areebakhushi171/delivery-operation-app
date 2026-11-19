import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/cloudinary_service.dart';
import '../../utils/utils.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'firestore_helpers.dart';

class FirebaseExceptionRepository implements ExceptionRepository {
  FirebaseExceptionRepository(FirebaseFirestore db) : _h = FirestoreHelpers(db);
  final FirestoreHelpers _h;

  FirebaseFirestore get _db => _h.db;

  /// Bounded to recent 14-day operational window to avoid loading old exception archives on live snapshots.
  @override
  Stream<List<DeliveryException>> watchAll() {
    final fourteenDaysAgo = DateTime.now().subtract(const Duration(days: 14)).millisecondsSinceEpoch;
    return _h.exceptions
        .where('reportedAt', isGreaterThanOrEqualTo: fourteenDaysAgo)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => DeliveryException.fromMap(d.data())).toList();
      list.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      return list;
    });
  }

  /// Real-time stream of open/pending delivery exceptions ('reported').
  @override
  Stream<List<DeliveryException>> watchActiveExceptions() {
    return _h.exceptions
        .where('status', isEqualTo: ExceptionStatus.reported.name)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => DeliveryException.fromMap(d.data())).toList();
      list.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      return list;
    });
  }

  /// Real-time stream of rider's active and recent exceptions (last 14 days).
  /// Uses a single-field query ('riderId') so no composite index in Firebase Console is required.
  @override
  Stream<List<DeliveryException>> watchForRider(String riderId) {
    final fourteenDaysAgo = DateTime.now().subtract(const Duration(days: 14)).millisecondsSinceEpoch;
    return _h.exceptions
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => DeliveryException.fromMap(d.data()))
          .where((e) => e.reportedAt.millisecondsSinceEpoch >= fourteenDaysAgo || e.status.isOpen)
          .toList();
      list.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      return list;
    });
  }

  /// Cursor-based pagination for historical/closed exceptions.
  @override
  Future<List<DeliveryException>> fetchExceptionHistory({
    int limit = 20,
    DeliveryException? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _h.exceptions
        .where('status', whereIn: [
          ExceptionStatus.rescheduled.name,
          ExceptionStatus.reassigned.name,
          ExceptionStatus.rto.name,
          ExceptionStatus.resolved.name,
        ]);

    if (startAfter != null) {
      final startDoc = await _h.exceptions.doc(startAfter.id).get();
      if (startDoc.exists) {
        query = query.startAfterDocument(startDoc);
      }
    }

    final snap = await query.get(const GetOptions(source: Source.serverAndCache));
    final list = snap.docs.map((d) => DeliveryException.fromMap(d.data())).toList();
    list.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return list.take(limit).toList();
  }

  @override
  Future<void> report(DeliveryException exception, String byUid) async {
    var ex = exception;
    final path = exception.photoPath;
    if (path != null && path.isNotEmpty && !path.startsWith('http')) {
      final secureUrl = await CloudinaryService.uploadImage(
        file: File(path),
        folder: 'delivery-operations/delivery-issues',
      );
      ex = exception.copyWith(photoPath: secureUrl);
    }
    await _db.runTransaction((tx) async {
      final exRef = _h.exceptions.doc(ex.id);
      final orderRef = _h.orders.doc(ex.orderId);
      final exSnap = await tx.get(exRef);
      final orderSnap = await tx.get(orderRef);
      if (exSnap.exists) return; // idempotent
      if (!orderSnap.exists) throw const AppException('Order not found.');
      final o = DeliveryOrder.fromMap(orderSnap.data()!);
      if (o.riderId != byUid) throw const AppException('This delivery is not assigned to you.');
      if (!o.status.isActive) throw const AppException('Only active deliveries can be reported.');
      final entry = StatusEntry(
        status: OrderStatus.failed,
        at: DateTime.now(),
        byUid: byUid,
        note: 'Exception: ${ex.reason.label}',
      );
      tx.set(exRef, {...ex.toMap(), 'serverAt': FieldValue.serverTimestamp()});
      tx.update(orderRef, {
        'status': OrderStatus.failed.name,
        'history': FieldValue.arrayUnion([entry.toMap()]),
      });
      tx.update(_h.riders.doc(byUid), {'currentOrderId': null, 'currentStop': null, 'etaMinutes': null});
      _h.history(tx, o.id, entry);
      _h.notify(tx,
          to: 'admin',
          type: NotificationType.exceptionUpdate,
          title: 'Exception reported',
          body: '${o.id} - ${ex.reason.label} (${ex.riderName} #${ex.riderStaffId}).',
          orderId: o.id);
      _h.audit(tx, 'exception.report', byUid, ex.id, {'orderId': o.id});
    });
  }

  @override
  Future<void> resolve({
    required String exceptionId,
    required ExceptionStatus outcome,
    required String byUid,
    String? note,
    String? newRiderId,
    DateTime? newStart,
    DateTime? newEnd,
  }) async {
    if (outcome == ExceptionStatus.reported) throw const AppException('Invalid resolution.');
    final noteText = (note ?? '').trim();
    // Dispatcher ka message rider ki notification mein jata hai
    final suffix = noteText.isEmpty ? '' : ' Note: $noteText';
    final stop = (outcome == ExceptionStatus.reassigned && newRiderId != null)
        ? await _h.nextStop(newRiderId)
        : 0;
    await _db.runTransaction((tx) async {
      final exRef = _h.exceptions.doc(exceptionId);
      final exSnap = await tx.get(exRef);
      if (!exSnap.exists) throw const AppException('Exception not found.');
      final ex = DeliveryException.fromMap(exSnap.data()!);
      if (!ex.status.isOpen) throw const AppException('This exception is already closed.');
      final orderSnap = await tx.get(_h.orders.doc(ex.orderId));
      if (!orderSnap.exists) throw const AppException('Order not found.');
      final order = DeliveryOrder.fromMap(orderSnap.data()!);
      Rider? rider;
      if (outcome == ExceptionStatus.reassigned) {
        if (newRiderId == null) throw const AppException('Select a courier.');
        final rs = await tx.get(_h.riders.doc(newRiderId));
        if (!rs.exists) throw const AppException('Rider not found.');
        rider = Rider.fromMap(rs.data()!);
      }
      switch (outcome) {
        case ExceptionStatus.rescheduled:
          if (newStart == null || newEnd == null) throw const AppException('Pick a new delivery window.');
          _h.applyReschedule(tx, order: order, start: newStart, end: newEnd, byUid: byUid);
          if (noteText.isNotEmpty) {
            _h.notify(tx,
                to: ex.riderId,
                type: NotificationType.exceptionUpdate,
                title: 'Dispatcher message',
                body: 'Order ${ex.orderId} rescheduled.$suffix',
                orderId: ex.orderId);
          }
          break;
        case ExceptionStatus.reassigned:
          _h.applyAssign(tx,
              order: order, rider: rider!, stop: stop, byUid: byUid, note: 'Reassigned after exception');
          if (newRiderId != ex.riderId) {
            _h.notify(tx,
                to: ex.riderId,
                type: NotificationType.exceptionUpdate,
                title: 'Delivery reassigned',
                body: 'Order ${ex.orderId} was moved to another courier.$suffix',
                orderId: ex.orderId);
          }
          break;
        case ExceptionStatus.rto:
          final entry = StatusEntry(
              status: OrderStatus.failed, at: DateTime.now(), byUid: byUid, note: 'Return to origin');
          tx.update(_h.orders.doc(order.id), {
            'history': FieldValue.arrayUnion([entry.toMap()]),
          });
          _h.notify(tx,
              to: ex.riderId,
              type: NotificationType.exceptionUpdate,
              title: 'Return to origin',
              body: 'Return ${ex.orderId} to the hub.$suffix',
              orderId: ex.orderId);
          break;
        case ExceptionStatus.resolved:
          _h.notify(tx,
              to: ex.riderId,
              type: NotificationType.exceptionUpdate,
              title: 'Exception resolved',
              body: 'Dispatcher closed the report for ${ex.orderId}.$suffix',
              orderId: ex.orderId);
          break;
        case ExceptionStatus.reported:
          break;
      }
      tx.update(exRef, {
        'status': outcome.name,
        'resolutionNote': note,
        'resolvedAt': DateTime.now().millisecondsSinceEpoch,
        'resolvedBy': byUid,
      });
      _h.audit(tx, 'exception.resolve', byUid, exceptionId, {'outcome': outcome.name});
    });
  }
}