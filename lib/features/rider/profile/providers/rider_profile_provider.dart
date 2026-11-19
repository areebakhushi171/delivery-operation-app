import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/data/data.dart';
import '../../../../core/providers/base_provider.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/location_service.dart';

/// Configurable thresholds for intelligent GPS telemetry synchronization.
class TelemetryConfig {
  TelemetryConfig._();

  /// Minimum distance moved (in meters) to trigger a Firestore telemetry upload.
  static const double minDistanceMeters = 25.0;

  /// Minimum time between consecutive Firestore telemetry uploads.
  static const Duration minUpdateInterval = Duration(seconds: 10);

  /// Maximum time a stationary rider can go without uploading a position update (heartbeat fallback).
  static const Duration maxStationaryInterval = Duration(seconds: 60);

  /// Minimum heading change (in degrees) to trigger an upload if moving > 5 km/h.
  static const double minHeadingChangeDegrees = 30.0;

  /// Maximum acceptable GPS inaccuracy radius in meters.
  static const double maxAcceptableAccuracyMeters = 50.0;
}

/// Rider document + duty status + (real-device mode only) smart GPS telemetry.
class RiderProfileProvider extends BaseProvider {
  RiderProfileProvider(this._repo, this._location);

  final RiderRepository _repo;
  final LocationService _location;
  StreamSubscription<Rider?>? _sub;
  StreamSubscription<Position>? _posSub;
  String? _riderId;
  Rider? _rider;
  LocationAccess? _locationIssue;

  // Tracking state cache
  DateTime _lastSentTime = DateTime.fromMillisecondsSinceEpoch(0);
  double? _lastSentLat;
  double? _lastSentLng;
  double? _lastSentHeading;

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

  Future<bool> updateProfilePhoto(File file) async {
    final id = _riderId;
    if (id == null) return false;
    final ok = await guard(() async {
      final secureUrl = await CloudinaryService.uploadImage(
        file: file,
        folder: 'delivery-operations/profile-images',
      );
      await _repo.updateProfilePhoto(id, secureUrl);
      return true;
    });
    return ok ?? false;
  }

  Future<bool> removeProfilePhoto() async {
    final id = _riderId;
    if (id == null) return false;
    final ok = await guard(() async {
      await _repo.updateProfilePhoto(id, null);
      return true;
    });
    return ok ?? false;
  }

  void _syncTracking() {
    if (!AppConfig.useFirebase) return; // mock mode keeps seed telemetry
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
      if (id == null) return;
      if (_shouldUploadPosition(p)) {
        await _uploadPosition(id, p);
      }
    });
  }

  bool _shouldUploadPosition(Position p, {bool isForced = false}) {
    if (isForced) return true;

    // 1. Ignore inaccurate GPS fixes
    if (p.accuracy > TelemetryConfig.maxAcceptableAccuracyMeters) {
      return false;
    }

    final now = DateTime.now();
    final timeSinceLast = now.difference(_lastSentTime);

    // 2. Minimum time interval check
    if (timeSinceLast < TelemetryConfig.minUpdateInterval) {
      return false;
    }

    // 3. Heartbeat check for stationary rider
    if (timeSinceLast >= TelemetryConfig.maxStationaryInterval) {
      return true;
    }

    // 4. Distance moved check
    if (_lastSentLat != null && _lastSentLng != null) {
      final distanceMeters = Geolocator.distanceBetween(
        _lastSentLat!,
        _lastSentLng!,
        p.latitude,
        p.longitude,
      );
      if (distanceMeters >= TelemetryConfig.minDistanceMeters) {
        return true;
      }
    } else {
      // Initial fix
      return true;
    }

    // 5. Heading change check
    if (p.speed * 3.6 > 5.0 && _lastSentHeading != null) {
      final headingDiff = (p.heading - _lastSentHeading!).abs();
      final normalizedDiff = headingDiff > 180 ? 360 - headingDiff : headingDiff;
      if (normalizedDiff >= TelemetryConfig.minHeadingChangeDegrees) {
        return true;
      }
    }

    return false;
  }

  Future<void> _uploadPosition(String id, Position p) async {
    _lastSentTime = DateTime.now();
    _lastSentLat = p.latitude;
    _lastSentLng = p.longitude;
    _lastSentHeading = p.heading;

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
  }

  void _stopTracking() {
    _posSub?.cancel();
    _posSub = null;
    _lastSentLat = null;
    _lastSentLng = null;
    _lastSentHeading = null;
    _lastSentTime = DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> openLocationSettings() => _location.openSettings();

  @override
  void dispose() {
    _sub?.cancel();
    _stopTracking();
    super.dispose();
  }
}
