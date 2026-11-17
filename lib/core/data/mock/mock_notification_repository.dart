import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_store.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this._s);
  final MockStore _s;

  @override
  Stream<List<AppNotification>> watch(String recipientId) => _s.notifications.watch().map(
        (l) => (l.where((n) => n.recipientId == recipientId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt))),
      );

  @override
  Future<void> send(AppNotification n) async =>
      _s.notifications.value = [n, ..._s.notifications.value];

  @override
  Future<void> markRead(String id) async => _s.notifications.value = [
        for (final n in _s.notifications.value) n.id == id ? n.copyWith(read: true) : n,
      ];

  @override
  Future<void> markAllRead(String recipientId) async => _s.notifications.value = [
        for (final n in _s.notifications.value)
          n.recipientId == recipientId ? n.copyWith(read: true) : n,
      ];
}
