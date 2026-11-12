import 'package:geolocator/geolocator.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

/// Foreground location only. Background location is intentionally NOT enabled
/// (it needs extra platform permissions and store review) - see README.
class LocationService {
  Future<LocationAccess> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceDisabled;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.deniedForever) return LocationAccess.deniedForever;
    if (p == LocationPermission.denied) return LocationAccess.denied;
    return LocationAccess.granted;
  }

  /// Battery-conscious: only emits after moving 30 m.
  Stream<Position> positions() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 30,
        ),
      );

  Future<bool> openSettings() => Geolocator.openAppSettings();
}
