import 'enums.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.read = false,
  });

  /// A user uid, or the literal 'admin' for broadcasts to all dispatchers.
  final String recipientId;
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? orderId;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        recipientId: recipientId,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        orderId: orderId,
        read: read ?? this.read,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'recipientId': recipientId,
        'type': type.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'orderId': orderId,
        'read': read,
      };

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String? ?? '',
        recipientId: m['recipientId'] as String? ?? '',
        type: NotificationType.parse(m['type'] as String?),
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num?)?.toInt() ?? 0),
        orderId: m['orderId'] as String?,
        read: m['read'] as bool? ?? false,
      );
}
