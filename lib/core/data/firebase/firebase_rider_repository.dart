import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

class FirebaseRiderRepository implements RiderRepository {
  FirebaseRiderRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _riders => _db.collection('riders');

  @override
  Stream<List<Rider>> watchRiders() {
    return _riders.snapshots().map((riderSnap) {
      return riderSnap.docs.map((d) => Rider.fromMap(d.data())).toList();
    });
  }

  @override
  Stream<Rider?> watchRider(String riderId) => _riders
      .doc(riderId)
      .snapshots()
      .map((d) => d.exists ? Rider.fromMap(d.data()!) : null)
      .handleError((e) {
        debugPrint('watchRider Firestore stream notice: $e');
        return null;
      });

  @override
  Future<void> setDuty(String riderId, DutyStatus duty) =>
      _riders.doc(riderId).set({'dutyStatus': duty.name}, SetOptions(merge: true));

  @override
  Future<void> updateTelemetry(
    String riderId, {
    required double lat,
    required double lng,
    double? speedKmh,
    double? heading,
    int? battery,
  }) =>
      _riders.doc(riderId).set({
        'lat': lat,
        'lng': lng,
        if (speedKmh != null) 'speedKmh': speedKmh,
        if (heading != null) 'heading': heading,
        if (battery != null) 'battery': battery,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'telemetrySource': 'device',
        'serverUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  @override
  Future<void> updateProfile(String riderId, {required String name, required String phone}) =>
      _riders.doc(riderId).set({'name': name, 'phone': phone}, SetOptions(merge: true));

  @override
  Future<void> updateProfilePhoto(String riderId, String? photoUrl) =>
      _riders.doc(riderId).set({'photoUrl': photoUrl}, SetOptions(merge: true));
}
