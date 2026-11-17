import 'dart:async';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'base_provider.dart';

/// Real-time notifications for the signed-in user (riders: own uid, admins: 'admin').
class NotificationsProvider extends BaseProvider {
  NotificationsProvider(this._repo);

  final NotificationRepository _repo;
  StreamSubscription<List<AppNotification>>? _sub;
  String? _recipientId;
  List<AppNotification> _items = const [];
  bool _loaded = false;

  List<AppNotification> get items => _items;
  bool get isLoading => _recipientId != null && !_loaded;
  int get unreadCount => _items.where((n) => !n.read).length;

  void bind(AppUser? user) {
    final id = user == null ? null : (user.role == UserRole.admin ? 'admin' : user.uid);
    if (id == _recipientId) return;
    _recipientId = id;
    _sub?.cancel();
    _sub = null;
    _items = const [];
    _loaded = false;
    if (id != null) {
      _sub = _repo.watch(id).listen((l) {
        _items = l;
        _loaded = true;
        notifyListeners();
      }, onError: (Object _) {
        _loaded = true;
        setError('Could not load notifications.');
        notifyListeners();
      });
    }
    notifyLater();
  }

  Future<void> markRead(String id) => _repo.markRead(id);
  Future<void> markAllRead() async {
    if (_recipientId != null) await _repo.markAllRead(_recipientId!);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
