import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../utils/utils.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'firestore_helpers.dart';

class FirebaseOrderRepository implements OrderRepository {
  FirebaseOrderRepository(FirebaseFirestore db, this._storage) : _h = FirestoreHelpers(db);
  final FirestoreHelpers _h;
  final FirebaseStorage _storage;

  FirebaseFirestore get _db => _h.db;

  @override
  Stream<List<DeliveryOrder>> watchAllOrders() => _h.orders
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DeliveryOrder.fromMap(d.data())).toList());

  @override
  Stream<List<DeliveryOrder>> watchRiderOrders(String riderId) => _h.orders
      .where('riderId', isEqualTo: riderId)
      .snapshots()
      .map((s) => s.docs.map((d) => DeliveryOrder.fromMap(d.data())).toList());

  @override
  Future<DeliveryOrder> createOrder(DeliveryOrder draft, String byUid) async {
    final counter = _db.collection('counters').doc('orders');
    late DeliveryOrder created;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(counter);
      final next = ((snap.data()?['next'] as num?)?.toInt() ?? 9000) + 1;
      final now = DateTime.now();
      final lat = draft.lat ?? (33.6844 + (math.Random().nextDouble() - 0.5) * 0.04);
      final lng = draft.lng ?? (73.0479 + (math.Random().nextDouble() - 0.5) * 0.04);

      created = draft.copyWith(
        id: 'PK-$next',
        lat: lat,
        lng: lng,
        distanceKm: draft.distanceKm > 0 ? draft.distanceKm : 2.5 + math.Random().nextDouble() * 5.0,
        etaMinutes: draft.etaMinutes ?? (10 + math.Random().nextInt(20)),
        createdAt: now,
        history: [
          StatusEntry(
            status: draft.riderId != null ? OrderStatus.assigned : OrderStatus.unassigned,
            at: now,
            byUid: byUid,
            note: draft.riderId != null ? 'Order created & assigned' : 'Order created',
          ),
        ],
      );
      tx.set(counter, {'next': next});
      tx.set(_h.orders.doc(created.id), {
        ...created.toMap(),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });

      if (draft.riderId != null) {
        tx.update(_h.riders.doc(draft.riderId!), {
          'currentOrderId': created.id,
        });
      }

      _h.history(tx, created.id, created.history.first);
      _h.audit(tx, 'order.create', byUid, created.id);
    });
    return created;
  }

  @override
  Future<void> assignRider({
    required String orderId,
    required String riderId,
    required String byUid,
  }) async {
    final stop = await _h.nextStop(riderId);
    await _db.runTransaction((tx) async {
      final orderSnap = await tx.get(_h.orders.doc(orderId));
      final riderSnap = await tx.get(_h.riders.doc(riderId));
      if (!orderSnap.exists) throw const AppException('Order not found.');
      if (!riderSnap.exists) throw const AppException('Rider not found.');
      _h.applyAssign(
        tx,
        order: DeliveryOrder.fromMap(orderSnap.data()!),
        rider: Rider.fromMap(riderSnap.data()!),
        stop: stop,
        byUid: byUid,
      );
    });
  }

  @override
  Future<void> updateStatus({
    required String orderId,
    required OrderStatus next,
    required String byUid,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _h.orders.doc(orderId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw const AppException('Order not found.');
      final o = DeliveryOrder.fromMap(snap.data()!);
      if (o.riderId != byUid) throw const AppException('This delivery is not assigned to you.');
      if (o.status == next) return; // idempotent
      if (next == OrderStatus.delivered) {
        throw const AppException('Complete delivery with photo proof of delivery.');
      }
      if (!o.status.canMoveTo(next)) {
        throw AppException('Cannot move from ${o.status.label} to ${next.label}.');
      }
      final entry = StatusEntry(status: next, at: DateTime.now(), byUid: byUid);
      tx.update(ref, {
        'status': next.name,
        'history': FieldValue.arrayUnion([entry.toMap()]),
      });
      if (next == OrderStatus.outForDelivery) {
        tx.update(_h.riders.doc(byUid), {
          'currentOrderId': o.id,
          'currentStop': o.stopNumber,
          'etaMinutes': o.etaMinutes,
        });
      }
      _h.history(tx, orderId, entry);
      _h.audit(tx, 'order.status', byUid, orderId, {'to': next.name});
    });
  }

  @override
  Future<void> submitProof({required DeliveryProof proof, required String byUid}) async {
    if (proof.photoPath.isEmpty) throw const AppException('A delivery photo is required.');
    var toSave = proof;
    if (!proof.photoPath.startsWith('http')) {
      final ref = _storage.ref('delivery_proofs/${proof.orderId}/photo.jpg');
      await ref.putFile(File(proof.photoPath), SettableMetadata(contentType: 'image/jpeg'));
      toSave = proof.copyWith(photoPath: await ref.getDownloadURL());
    }
    await _db.runTransaction((tx) async {
      final ref = _h.orders.doc(proof.orderId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw const AppException('Order not found.');
      final o = DeliveryOrder.fromMap(snap.data()!);
      if (o.riderId != byUid) throw const AppException('This delivery is not assigned to you.');
      if (o.status == OrderStatus.delivered) return; // idempotent
      if (o.status != OrderStatus.outForDelivery) {
        throw const AppException('Order must be Out for Delivery before proof can be submitted.');
      }
      if (o.isCod && !toSave.codAcknowledged) {
        throw const AppException('Please confirm the COD amount was collected.');
      }
      final entry = StatusEntry(status: OrderStatus.delivered, at: DateTime.now(), byUid: byUid);
      final saved = DeliveryProof(
        orderId: toSave.orderId,
        photoPath: toSave.photoPath,
        recipientName: toSave.recipientName,
        notes: toSave.notes,
        codAcknowledged: toSave.codAcknowledged,
        submittedAt: toSave.submittedAt,
        submittedBy: byUid,
      );
      tx.update(ref, {
        'status': OrderStatus.delivered.name,
        'proof': saved.toMap(),
        'codCollected': o.isCod,
        'history': FieldValue.arrayUnion([entry.toMap()]),
      });
      tx.set(_db.collection('delivery_proofs').doc(o.id), {
        ...saved.toMap(),
        'serverAt': FieldValue.serverTimestamp(),
      });
      if (o.isCod) {
        tx.set(_db.collection('cod_transactions').doc(o.id), {
          'orderId': o.id,
          'riderId': byUid,
          'amount': o.codAmount,
          'collected': true,
          'deposited': false,
          'collectedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.update(_h.riders.doc(byUid), {
        'currentOrderId': null,
        'currentStop': null,
        'etaMinutes': null,
      });
      _h.history(tx, o.id, entry);
      _h.notify(tx,
          to: 'admin',
          type: NotificationType.announcement,
          title: 'Delivered',
          body: '${o.id} delivered to ${saved.recipientName}.',
          orderId: o.id);
      _h.audit(tx, 'order.delivered', byUid, o.id, {'cod': o.isCod ? o.codAmount : 0});
    });
  }

  @override
  Future<void> reschedule({
    required String orderId,
    required DateTime start,
    required DateTime end,
    required String byUid,
  }) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_h.orders.doc(orderId));
      if (!snap.exists) throw const AppException('Order not found.');
      _h.applyReschedule(tx,
          order: DeliveryOrder.fromMap(snap.data()!), start: start, end: end, byUid: byUid);
    });
  }

  @override
  Future<void> cancelOrder({
    required String orderId,
    required String byUid,
    String? reason,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _h.orders.doc(orderId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw const AppException('Order not found.');
      final o = DeliveryOrder.fromMap(snap.data()!);
      if (o.status == OrderStatus.delivered) {
        throw const AppException('Delivered orders cannot be cancelled.');
      }
      final entry = StatusEntry(
        status: OrderStatus.failed,
        at: DateTime.now(),
        byUid: byUid,
        note: reason ?? 'Cancelled by Admin',
      );
      tx.update(ref, {
        'status': OrderStatus.failed.name,
        'history': FieldValue.arrayUnion([entry.toMap()]),
      });
      if (o.riderId != null) {
        tx.update(_h.riders.doc(o.riderId!), {
          'currentOrderId': null,
          'currentStop': null,
        });
      }
      _h.history(tx, orderId, entry);
      _h.audit(tx, 'order.cancel', byUid, orderId, {'reason': reason});
    });
  }

  @override
  Future<void> reconcileCod({required String orderId, required String byUid}) async {
    await _db.runTransaction((tx) async {
      final ref = _h.orders.doc(orderId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw const AppException('Order not found.');
      final o = DeliveryOrder.fromMap(snap.data()!);
      if (!o.isCod || !o.codCollected) throw const AppException('No collected COD to reconcile.');
      if (o.codDeposited) return;
      tx.update(ref, {'codDeposited': true});
      tx.set(_db.collection('cod_transactions').doc(orderId),
          {'deposited': true, 'depositedAt': FieldValue.serverTimestamp(), 'depositedBy': byUid},
          SetOptions(merge: true));
      _h.audit(tx, 'cod.reconcile', byUid, orderId, {'amount': o.codAmount});
    });
  }
}
