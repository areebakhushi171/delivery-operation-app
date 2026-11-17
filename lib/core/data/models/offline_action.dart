import 'dart:convert';

import 'enums.dart';

class OfflineAction {
  const OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.state = SyncState.pending,
    this.error,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final SyncState state;
  final String? error;

  OfflineAction copyWith({SyncState? state, String? error}) => OfflineAction(
        id: id,
        type: type,
        payload: payload,
        createdAt: createdAt,
        state: state ?? this.state,
        error: error,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'state': state.name,
        'error': error,
      };

  factory OfflineAction.fromMap(Map<String, dynamic> m) => OfflineAction(
        id: m['id'] as String,
        type: m['type'] as String,
        payload: Map<String, dynamic>.from(m['payload'] as Map),
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num).toInt()),
        state: parseEnum(SyncState.values, m['state'] as String?, SyncState.pending),
        error: m['error'] as String?,
      );

  static String encodeList(List<OfflineAction> l) => jsonEncode(l.map((e) => e.toMap()).toList());
  static List<OfflineAction> decodeList(String s) => (jsonDecode(s) as List)
      .map((e) => OfflineAction.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();
}
