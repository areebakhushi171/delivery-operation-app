import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/app_exception.dart';

/// Shared busy/error handling. UI never catches repository exceptions itself.
abstract class BaseProvider extends ChangeNotifier {
  bool _busy = false;
  bool _disposed = false;
  String? _error;

  bool get isBusy => _busy;
  String? get error => _error;

  @protected
  void setError(String? message) => _error = message;

  /// Runs [action]; returns null on failure and exposes [error].
  Future<T?> guard<T>(Future<T> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      return await action();
    } on AppException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      debugPrint('Unexpected error: $e');
      _error = 'Something went wrong. Please try again.';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Safe to call while the widget tree is building (e.g. inside ProxyProvider.update).
  @protected
  void notifyLater() => scheduleMicrotask(notifyListeners);

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
