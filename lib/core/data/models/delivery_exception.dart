import 'enums.dart';

DateTime? _dt(Object? v) =>
    v == null ? null : DateTime.fromMillisecondsSinceEpoch((v as num).toInt());

class DeliveryException {
  const DeliveryException({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.riderId,
    required this.riderName,
    required this.riderStaffId,
    required this.reason,
    required this.description,
    required this.codAmount,
    required this.reportedAt,
    this.photoPath,
    this.rescheduleRequestedAt,
    this.status = ExceptionStatus.reported,
    this.resolutionNote,
    this.resolvedAt,
    this.resolvedBy,
  });

  final String id;
  final String orderId;
  final String customerName;
  final String riderId;
  final String riderName;
  final String riderStaffId;
  final ExceptionReason reason;
  final String description;
  final int codAmount;
  final DateTime reportedAt;
  final String? photoPath;
  final DateTime? rescheduleRequestedAt;
  final ExceptionStatus status;
  final String? resolutionNote;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  DeliveryException copyWith({
    String? photoPath,
    ExceptionStatus? status,
    String? resolutionNote,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) =>
      DeliveryException(
        id: id,
        orderId: orderId,
        customerName: customerName,
        riderId: riderId,
        riderName: riderName,
        riderStaffId: riderStaffId,
        reason: reason,
        description: description,
        codAmount: codAmount,
        reportedAt: reportedAt,
        photoPath: photoPath ?? this.photoPath,
        rescheduleRequestedAt: rescheduleRequestedAt,
        status: status ?? this.status,
        resolutionNote: resolutionNote ?? this.resolutionNote,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        resolvedBy: resolvedBy ?? this.resolvedBy,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'customerName': customerName,
        'riderId': riderId,
        'riderName': riderName,
        'riderStaffId': riderStaffId,
        'reason': reason.name,
        'description': description,
        'codAmount': codAmount,
        'reportedAt': reportedAt.millisecondsSinceEpoch,
        'photoPath': photoPath,
        'rescheduleRequestedAt': rescheduleRequestedAt?.millisecondsSinceEpoch,
        'status': status.name,
        'resolutionNote': resolutionNote,
        'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
        'resolvedBy': resolvedBy,
      };

  factory DeliveryException.fromMap(Map<String, dynamic> m) => DeliveryException(
        id: m['id'] as String? ?? '',
        orderId: m['orderId'] as String? ?? '',
        customerName: m['customerName'] as String? ?? '',
        riderId: m['riderId'] as String? ?? '',
        riderName: m['riderName'] as String? ?? '',
        riderStaffId: m['riderStaffId'] as String? ?? '',
        reason: ExceptionReason.parse(m['reason'] as String?),
        description: m['description'] as String? ?? '',
        codAmount: (m['codAmount'] as num?)?.toInt() ?? 0,
        reportedAt: _dt(m['reportedAt']) ?? DateTime.now(),
        photoPath: m['photoPath'] as String?,
        rescheduleRequestedAt: _dt(m['rescheduleRequestedAt']),
        status: ExceptionStatus.parse(m['status'] as String?),
        resolutionNote: m['resolutionNote'] as String?,
        resolvedAt: _dt(m['resolvedAt']),
        resolvedBy: m['resolvedBy'] as String?,
      );
}
