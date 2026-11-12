import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/data/data.dart';
import '../../../../core/providers/base_provider.dart';
import '../../../../core/services/location_service.dart';

/// Rider document + duty status + (real-device mode only) GPS telemetry.
/// Location is uploaded ONLY while On Duty, at most every 10 seconds.
class RiderProfileProvider extends BaseProvider {
  RiderProfileProvider(this._repo, this._location);

  final RiderRepository _repo;
  final LocationService _location;
  StreamSubscription<Rider?>? _sub;
  StreamSubscription<Position>? _posSub;
  String? _riderId;
  Rider? _rider;
  LocationAccess? _locationIssue;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  Rider? get rider => _rider;
  LocationAccess? get locationIssue => _locationIssue;

  void bind(AppUser? user) {
    final id = (user != null && user.role == UserRole.rider) ? user.uid : null;
    if (id == _riderId) return;
    _riderId = id;
    _sub?.cancel();
    _stopTracking();
    _rider = null;
    if (id != null) {
      _sub = _repo.watchRider(id).listen((r) {
        _rider = r;
        _syncTracking();
        notifyListeners();
      });
    }
    notifyLater();
  }

  Future<bool> setDuty(bool on) async {
    final id = _riderId;
    if (id == null) return false;
    final ok = await guard(() async {
      await _repo.setDuty(id, on ? DutyStatus.onDuty : DutyStatus.offDuty);
      return true;
    });
    return ok ?? false;
  }

  Future<bool> updateProfile({required String name, required String phone}) async {
    final id = _riderId;
    if (id == null) return false;
    final ok = await guard(() async {
      await _repo.updateProfile(id, name: name.trim(), phone: phone.trim());
      return true;
    });
    return ok ?? false;
  }

  void _syncTracking() {
    if (!AppConfig.useFirebase) return; // mock mode keeps seed telemetry (labelled as simulated)
    final on = _rider?.isOnDuty ?? false;
    if (on && _posSub == null) {
      _startTracking();
    } else if (!on && _posSub != null) {
      _stopTracking();
    }
  }

  Future<void> _startTracking() async {
    final access = await _location.ensurePermission();
    _locationIssue = access == LocationAccess.granted ? null : access;
    notifyListeners();
    if (access != LocationAccess.granted) return;
    _posSub = _location.positions().listen((p) async {
      final id = _riderId;
      if (id == null || DateTime.now().difference(_lastSent) < const Duration(seconds: 10)) return;
      _lastSent = DateTime.now();
      int? battery;
      try {
        battery = await Battery().batteryLevel;
      } catch (_) {}
      await _repo.updateTelemetry(
        id,
        lat: p.latitude,
        lng: p.longitude,
        speedKmh: p.speed < 0 ? null : p.speed * 3.6,
        heading: p.heading,
        battery: battery,
      );
    });
  }

  void _stopTracking() {
    _posSub?.cancel();
    _posSub = null;
  }

  Future<void> openLocationSettings() => _location.openSettings();

  @override
  void dispose() {
    _sub?.cancel();
    _stopTracking();
    super.dispose();
  }
}
