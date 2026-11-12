import 'package:flutter/material.dart';

import '../storage/local_storage.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._storage) {
    final savedMode = _storage.getString(StorageKeys.themeMode);
    _mode = savedMode == 'dark' ? ThemeMode.dark : (savedMode == 'light' ? ThemeMode.light : ThemeMode.system);

    final savedAccent = _storage.getString('accent_color_hex');
    if (savedAccent != null) {
      final val = int.tryParse(savedAccent);
      if (val != null) {
        _accentColor = Color(val);
      }
    }
  }

  final LocalStorage _storage;
  late ThemeMode _mode;
  Color _accentColor = const Color(0xFF1565C0); // Original Cobalt Blue brand color

  ThemeMode get mode => _mode;
  Color get accentColor => _accentColor;

  bool isDark(BuildContext context) =>
      _mode == ThemeMode.dark ||
      (_mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

  Future<void> setDark(bool dark) async {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _storage.setString(StorageKeys.themeMode, dark ? 'dark' : 'light');
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    await _storage.setString('accent_color_hex', color.toARGB32().toString());
  }
}
