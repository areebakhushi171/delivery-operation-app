import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('notifications');

  @override
  Stream<List<AppNotification>> watch(String recipientId) =>
      _col.where('recipientId', isEqualTo: recipientId).snapshots().map(
            (s) => s.docs.map((d) => AppNotification.fromMap(d.data())).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          );

  @override
  Future<void> send(AppNotification n) => _col.doc(n.id).set(n.toMap());

  @override
  Future<void> markRead(String id) => _col.doc(id).update({'read': true});

  @override
  Future<void> markAllRead(String recipientId) async {
    final unread = await _col
        .where('recipientId', isEqualTo: recipientId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
