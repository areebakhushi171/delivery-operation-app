import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../storage/local_storage.dart';

typedef SyncHandler = Future<void> Function(Map<String, dynamic> payload);

/// Offline queue. Actions are persisted, replayed when the network returns,
/// and handlers are idempotent on the backend, so duplicates cannot happen.
/// Note: connectivity_plus reports network *interfaces*, not guaranteed internet.
class SyncProvider extends ChangeNotifier {
  SyncProvider(this._storage);

  final LocalStorage _storage;
  static const _uuid = Uuid();
  final Map<String, SyncHandler> _handlers = {};
  List<OfflineAction> _queue = [];
  bool _online = true;
  bool _syncing = false;
  bool _disposed = false;
  DateTime? _lastSync;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOnline => _online;
  bool get isSyncing => _syncing;
  List<OfflineAction> get queue => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  bool get hasFailed => _queue.any((a) => a.state == SyncState.failed);
  DateTime? get lastSync => _lastSync;

  bool _reachable(List<ConnectivityResult> r) => r.any((e) => e != ConnectivityResult.none);

  Future<void> init() async {
    final raw = _storage.getString(StorageKeys.offlineQueue);
    if (raw != null) {
      try {
        _queue = OfflineAction.decodeList(raw);
      } catch (_) {
        _queue = [];
      }
    }
    final ls = int.tryParse(_storage.getString(StorageKeys.lastSync) ?? '');
    if (ls != null) _lastSync = DateTime.fromMillisecondsSinceEpoch(ls);
    _online = _reachable(await Connectivity().checkConnectivity());
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      final was = _online;
      _online = _reachable(r);
      notifyListeners();
      if (!was && _online) syncNow();
    });
    notifyListeners();
    if (_online && _queue.isNotEmpty) unawaited(syncNow());
  }

  void registerHandler(String type, SyncHandler handler) => _handlers[type] = handler;

  Future<void> _persist() =>
      _storage.setString(StorageKeys.offlineQueue, OfflineAction.encodeList(_queue));

  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    _queue = [
      ..._queue,
      OfflineAction(id: _uuid.v4(), type: type, payload: payload, createdAt: DateTime.now()),
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> discard(String id) async {
    _queue = _queue.where((a) => a.id != id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (_syncing || !_online || _queue.isEmpty) return;
    _syncing = true;
    notifyListeners();
    for (final action in List<OfflineAction>.from(_queue)) {
      final handler = _handlers[action.type];
      if (handler == null) continue;
      _replace(action.copyWith(state: SyncState.syncing));
      try {
        await handler(action.payload);
        _queue = _queue.where((a) => a.id != action.id).toList();
        _lastSync = DateTime.now();
        await _storage.setString(StorageKeys.lastSync, '${_lastSync!.millisecondsSinceEpoch}');
      } catch (e) {
        _replace(action.copyWith(state: SyncState.failed, error: e.toString()));
      }
    }
    await _persist();
    _syncing = false;
    notifyListeners();
  }

  void _replace(OfflineAction a) {
    _queue = [for (final e in _queue) e.id == a.id ? a : e];
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
