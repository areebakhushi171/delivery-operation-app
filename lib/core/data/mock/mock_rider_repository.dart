import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_store.dart';

class MockRiderRepository implements RiderRepository {
  MockRiderRepository(this._s);
  final MockStore _s;

  @override
  Stream<List<Rider>> watchRiders() => _s.riders.watch();

  @override
  Stream<Rider?> watchRider(String riderId) =>
      _s.riders.watch().map((l) => l.where((r) => r.id == riderId).firstOrNull);

  @override
  Future<void> setDuty(String riderId, DutyStatus duty) async {
    _s.putRider(_s.requireRider(riderId).copyWith(dutyStatus: duty));
    _s.audit('rider.duty', riderId, riderId, {'duty': duty.name});
  }

  @override
  Future<void> updateTelemetry(
    String riderId, {
    required double lat,
    required double lng,
    double? speedKmh,
    double? heading,
    int? battery,
  }) async {
    _s.putRider(
      _s.requireRider(riderId).copyWith(
            lat: lat,
            lng: lng,
            speedKmh: speedKmh,
            heading: heading,
            battery: battery,
            lastUpdated: DateTime.now(),
            telemetrySource: 'device',
          ),
    );
  }

  @override
  Future<void> updateProfile(String riderId, {required String name, required String phone}) async =>
      _s.putRider(_s.requireRider(riderId).copyWith(name: name, phone: phone));

  @override
  Future<void> updateProfilePhoto(String riderId, String? photoUrl) async =>
      _s.putRider(_s.requireRider(riderId).copyWith(photoUrl: photoUrl, clearPhoto: photoUrl == null));
}
