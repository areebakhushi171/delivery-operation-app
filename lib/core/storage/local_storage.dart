import 'package:shared_preferences/shared_preferences.dart';

class StorageKeys {
  StorageKeys._();
  static const themeMode = 'theme_mode';
  static const rememberedId = 'remembered_identifier';
  static const rememberedRole = 'remembered_role';
  static const mockSession = 'mock_session_uid';
  static const offlineQueue = 'offline_queue';
  static const lastSync = 'last_sync_at';
  static const notificationsEnabled = 'notifications_enabled';
  static const language = 'language';
}

class LocalStorage {
  LocalStorage._(this._prefs);
  final SharedPreferences _prefs;

  static Future<LocalStorage> create() async =>
      LocalStorage._(await SharedPreferences.getInstance());

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  bool getBool(String key, {bool fallback = false}) => _prefs.getBool(key) ?? fallback;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
}
