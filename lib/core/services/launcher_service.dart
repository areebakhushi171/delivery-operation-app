import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  LauncherService._();

  static Future<bool> call(String phone) =>
      launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));

  static Future<bool> sms(String phone) =>
      launchUrl(Uri(scheme: 'sms', path: phone.replaceAll(' ', '')));

  /// Opens the device's real navigation app (Google Maps etc.) to the destination.
  static Future<bool> navigate(double lat, double lng, [String? address]) {
    final dest = (address != null && address.trim().isNotEmpty)
        ? Uri.encodeComponent(address.trim())
        : '$lat,$lng';
    return launchUrl(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$dest'),
      mode: LaunchMode.externalApplication,
    );
  }
}
