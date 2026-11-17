import 'package:flutter/foundation.dart';

import '../storage/local_storage.dart';

class PreferencesProvider extends ChangeNotifier {
  PreferencesProvider(this._storage)
      : _notifications = _storage.getBool(StorageKeys.notificationsEnabled, fallback: true),
        _language = _storage.getString(StorageKeys.language) ?? 'English';

  final LocalStorage _storage;
  bool _notifications;
  String _language;

  bool get notificationsEnabled => _notifications;
  String get language => _language;

  Future<void> setNotifications(bool v) async {
    _notifications = v;
    notifyListeners();
    await _storage.setBool(StorageKeys.notificationsEnabled, v);
  }

  Future<void> setLanguage(String v) async {
    _language = v;
    notifyListeners();
    await _storage.setString(StorageKeys.language, v);
  }
}
