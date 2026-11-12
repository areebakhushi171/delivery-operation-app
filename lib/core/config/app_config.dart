/// Central environment switch.
///
/// Firebase (default): flutter run
/// Mock (demo mode):  flutter run --dart-define=DATA_SOURCE=mock
class AppConfig {
  AppConfig._();

  static const String _source =
      String.fromEnvironment('DATA_SOURCE', defaultValue: 'firebase');

  /// Staff IDs are mapped to `<staffId>@<domain>` Firebase Auth emails so that
  /// "Email or Staff ID" login works without exposing a public user directory.
  static const String staffEmailDomain = String.fromEnvironment(
    'STAFF_EMAIL_DOMAIN',
    defaultValue: 'staff.deliveryops.app',
  );

  static bool get useFirebase => _source != 'mock';
  static bool get isMock => !useFirebase;
}
