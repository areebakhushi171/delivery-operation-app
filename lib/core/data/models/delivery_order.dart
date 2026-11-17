import 'enums.dart';

DateTime? _dt(Object? v) =>
    v == null ? null : DateTime.fromMillisecondsSinceEpoch((v as num).toInt());

class OrderItem {
  const OrderItem({required this.name, required this.quantity});
  final String name;
  final int quantity;

  Map<String, dynamic> toMap() => {'name': name, 'quantity': quantity};
  factory OrderItem.fromMap(Map<String, dynamic> m) =>
      OrderItem(name: m['name'] as String? ?? '', quantity: (m['quantity'] as num?)?.toInt() ?? 1);
}

class StatusEntry {
  const StatusEntry({required this.status, required this.at, required this.byUid, this.note});
  final OrderStatus status;
  final DateTime at;
  final String byUid;
  final String? note;

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'at': at.millisecondsSinceEpoch,
        'byUid': byUid,
        if (note != null) 'note': note,
      };
  factory StatusEntry.fromMap(Map<String, dynamic> m) => StatusEntry(
        status: OrderStatus.parse(m['status'] as String?),
        at: _dt(m['at']) ?? DateTime.now(),
        byUid: m['byUid'] as String? ?? '',
        note: m['note'] as String?,
      );
}

class DeliveryProof {
  const DeliveryProof({
    required this.orderId,
    required this.photoPath,
    required this.recipientName,
    required this.codAcknowledged,
    required this.submittedAt,
    this.notes,
    this.submittedBy,
  });

  final String orderId;

  /// Local file path before upload, https URL after upload.
  final String photoPath;
  final String recipientName;
  final String? notes;
  final bool codAcknowledged;
  final DateTime submittedAt;
  final String? submittedBy;

  DeliveryProof copyWith({String? photoPath}) => DeliveryProof(
        orderId: orderId,
        photoPath: photoPath ?? this.photoPath,
        recipientName: recipientName,
        codAcknowledged: codAcknowledged,
        submittedAt: submittedAt,
        notes: notes,
        submittedBy: submittedBy,
      );

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'photoPath': photoPath,
        'recipientName': recipientName,
        'notes': notes,
        'codAcknowledged': codAcknowledged,
        'submittedAt': submittedAt.millisecondsSinceEpoch,
        'submittedBy': submittedBy,
      };

  factory DeliveryProof.fromMap(Map<String, dynamic> m) => DeliveryProof(
        orderId: m['orderId'] as String? ?? '',
        photoPath: m['photoPath'] as String? ?? '',
        recipientName: m['recipientName'] as String? ?? '',
        notes: m['notes'] as String?,
        codAcknowledged: m['codAcknowledged'] as bool? ?? false,
        submittedAt: _dt(m['submittedAt']) ?? DateTime.now(),
        submittedBy: m['submittedBy'] as String?,
      );
}

/// Canonical order document, shared by Rider and Admin.
class DeliveryOrder {
  const DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.city,
    required this.area,
    required this.windowStart,
    required this.windowEnd,
    required this.createdAt,
    this.lat,
    this.lng,
    this.items = const [],
    this.instructions = '',
    this.paymentType = PaymentType.prepaid,
    this.codAmount = 0,
    this.prepaidAmount = 0,
    this.category = 'General',
    this.status = OrderStatus.unassigned,
    this.riderId,
    this.stopNumber,
    this.etaMinutes,
    this.distanceKm = 0,
    this.history = const [],
    this.codCollected = false,
    this.codDeposited = false,
    this.proof,
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final String address;
  final String city;
  final String area;
  final double? lat;
  final double? lng;
  final List<OrderItem> items;
  final String instructions;
  final PaymentType paymentType;
  final int codAmount;
  final int prepaidAmount;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String category;
  final OrderStatus status;
  final String? riderId;
  final int? stopNumber;
  final int? etaMinutes;
  final double distanceKm;
  final DateTime createdAt;
  final List<StatusEntry> history;
  final bool codCollected;
  final bool codDeposited;
  final DeliveryProof? proof;

  bool get isCod => paymentType == PaymentType.cod;
  int get amount => isCod ? codAmount : prepaidAmount;
  String get fullAddress => '$address, $area, $city';
  bool get hasLocation => lat != null && lng != null;
  bool isOverdue(DateTime now) => status.isActive && now.isAfter(windowEnd);

  DateTime? timeOf(OrderStatus s) {
    for (final e in history.reversed) {
      if (e.status == s) return e.at;
    }
    return null;
  }

  DateTime? get deliveredAt => status == OrderStatus.delivered ? timeOf(OrderStatus.delivered) : null;
  DateTime? get failedAt => status == OrderStatus.failed ? timeOf(OrderStatus.failed) : null;
  bool get deliveredOnTime => deliveredAt != null && !deliveredAt!.isAfter(windowEnd);

  DeliveryOrder copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? address,
    String? city,
    String? area,
    double? lat,
    double? lng,
    List<OrderItem>? items,
    String? instructions,
    PaymentType? paymentType,
    int? codAmount,
    int? prepaidAmount,
    DateTime? windowStart,
    DateTime? windowEnd,
    String? category,
    OrderStatus? status,
    String? riderId,
    int? stopNumber,
    int? etaMinutes,
    double? distanceKm,
    DateTime? createdAt,
    List<StatusEntry>? history,
    bool? codCollected,
    bool? codDeposited,
    DeliveryProof? proof,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      area: area ?? this.area,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      items: items ?? this.items,
      instructions: instructions ?? this.instructions,
      paymentType: paymentType ?? this.paymentType,
      codAmount: codAmount ?? this.codAmount,
      prepaidAmount: prepaidAmount ?? this.prepaidAmount,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      category: category ?? this.category,
      status: status ?? this.status,
      riderId: riderId ?? this.riderId,
      stopNumber: stopNumber ?? this.stopNumber,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      createdAt: createdAt ?? this.createdAt,
      history: history ?? this.history,
      codCollected: codCollected ?? this.codCollected,
      codDeposited: codDeposited ?? this.codDeposited,
      proof: proof ?? this.proof,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'address': address,
        'city': city,
        'area': area,
        'lat': lat,
        'lng': lng,
        'items': items.map((e) => e.toMap()).toList(),
        'instructions': instructions,
        'paymentType': paymentType.name,
        'codAmount': codAmount,
        'prepaidAmount': prepaidAmount,
        'windowStart': windowStart.millisecondsSinceEpoch,
        'windowEnd': windowEnd.millisecondsSinceEpoch,
        'category': category,
        'status': status.name,
        'riderId': riderId,
        'stopNumber': stopNumber,
        'etaMinutes': etaMinutes,
        'distanceKm': distanceKm,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'history': history.map((e) => e.toMap()).toList(),
        'codCollected': codCollected,
        'codDeposited': codDeposited,
        'proof': proof?.toMap(),
      };

  factory DeliveryOrder.fromMap(Map<String, dynamic> m) {
    List<Map<String, dynamic>> list(Object? v) =>
        (v as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return DeliveryOrder(
      id: m['id'] as String? ?? '',
      customerName: m['customerName'] as String? ?? '',
      customerPhone: m['customerPhone'] as String? ?? '',
      address: m['address'] as String? ?? '',
      city: m['city'] as String? ?? '',
      area: m['area'] as String? ?? '',
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      items: list(m['items']).map(OrderItem.fromMap).toList(),
      instructions: m['instructions'] as String? ?? '',
      paymentType: PaymentType.parse(m['paymentType'] as String?),
      codAmount: (m['codAmount'] as num?)?.toInt() ?? 0,
      prepaidAmount: (m['prepaidAmount'] as num?)?.toInt() ?? 0,
      windowStart: _dt(m['windowStart']) ?? DateTime.now(),
      windowEnd: _dt(m['windowEnd']) ?? DateTime.now(),
      category: m['category'] as String? ?? 'General',
      status: OrderStatus.parse(m['status'] as String?),
      riderId: m['riderId'] as String?,
      stopNumber: (m['stopNumber'] as num?)?.toInt(),
      etaMinutes: (m['etaMinutes'] as num?)?.toInt(),
      distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0,
      createdAt: _dt(m['createdAt']) ?? DateTime.now(),
      history: list(m['history']).map(StatusEntry.fromMap).toList(),
      codCollected: m['codCollected'] as bool? ?? false,
      codDeposited: m['codDeposited'] as bool? ?? false,
      proof: m['proof'] == null
          ? null
          : DeliveryProof.fromMap(Map<String, dynamic>.from(m['proof'] as Map)),
    );
  }
}
