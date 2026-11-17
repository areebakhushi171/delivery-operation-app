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
    return _db.collection('users').where('role', isEqualTo: 'rider').snapshots().asyncMap((userSnap) async {
      final userDocs = userSnap.docs;
      final ridersMap = <String, Rider>{};

      // 1. Fetch existing riders collection docs
      try {
        final riderSnap = await _riders.get();
        for (final doc in riderSnap.docs) {
          final data = doc.data();
          final r = Rider.fromMap(data);
          ridersMap[r.id] = r;
        }
      } catch (e) {
        debugPrint('watchRiders riders fetch notice: $e');
      }

      // 2. Ensure every user with role == 'rider' has a rider entry
      for (final uDoc in userDocs) {
        final uData = uDoc.data();
        final uid = uDoc.id;
        if (!ridersMap.containsKey(uid)) {
          final name = uData['name'] ?? uData['email']?.toString().split('@').first ?? 'Rider';
          final email = uData['email'] ?? '';
          final staffId = uData['staffId'] ?? 'R${uid.substring(0, 4).toUpperCase()}';
          final newRider = Rider(
            id: uid,
            staffId: staffId,
            name: name,
            phone: uData['phone'] ?? '+92 300 0000000',
            email: email,
            dutyStatus: DutyStatus.onDuty,
            vehicleType: 'Bike - CG125',
            vehicleReg: 'ICT-408',
          );
          ridersMap[uid] = newRider;
          _riders.doc(uid).set(newRider.toMap(), SetOptions(merge: true)).catchError((_) {});
        }
      }

      return ridersMap.values.toList();
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
