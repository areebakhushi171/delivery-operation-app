import '../../constants/app_constants.dart';
import 'enums.dart';

DateTime? _dt(Object? v) =>
    v == null ? null : DateTime.fromMillisecondsSinceEpoch((v as num).toInt());

/// Canonical rider document: profile + duty + telemetry.
class Rider {
  const Rider({
    required this.id,
    required this.staffId,
    required this.name,
    required this.phone,
    required this.email,
    this.vehicleType = 'Bike',
    this.vehicleReg = '',
    this.dutyStatus = DutyStatus.offDuty,
    this.rating = 0,
    this.lat,
    this.lng,
    this.speedKmh,
    this.battery,
    this.heading,
    this.currentOrderId,
    this.currentStop,
    this.etaMinutes,
    this.lastUpdated,
    this.telemetrySource = 'none',
  });

  final String id;
  final String staffId;
  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehicleReg;
  final DutyStatus dutyStatus;
  final double rating;
  final double? lat;
  final double? lng;
  final double? speedKmh;
  final int? battery;
  final double? heading;
  final String? currentOrderId;
  final int? currentStop;
  final int? etaMinutes;
  final DateTime? lastUpdated;

  /// 'device' = real GPS from the rider's phone, 'seed' = demo data, 'none'.
  final String telemetrySource;

  bool get isOnDuty => dutyStatus == DutyStatus.onDuty;
  bool get hasLocation => lat != null && lng != null;
  bool get isSeedTelemetry => telemetrySource == 'seed';

  /// Live only if real device telemetry arrived recently while on duty.
  bool isLive(DateTime now) =>
      isOnDuty &&
      telemetrySource == 'device' &&
      lastUpdated != null &&
      now.difference(lastUpdated!) < AppConstants.liveThreshold;

  Rider copyWith({
    String? name,
    String? phone,
    DutyStatus? dutyStatus,
    double? lat,
    double? lng,
    double? speedKmh,
    int? battery,
    double? heading,
    String? currentOrderId,
    int? currentStop,
    int? etaMinutes,
    bool clearCurrent = false,
    DateTime? lastUpdated,
    String? telemetrySource,
  }) {
    return Rider(
      id: id,
      staffId: staffId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email,
      vehicleType: vehicleType,
      vehicleReg: vehicleReg,
      dutyStatus: dutyStatus ?? this.dutyStatus,
      rating: rating,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speedKmh: speedKmh ?? this.speedKmh,
      battery: battery ?? this.battery,
      heading: heading ?? this.heading,
      currentOrderId: clearCurrent ? null : (currentOrderId ?? this.currentOrderId),
      currentStop: clearCurrent ? null : (currentStop ?? this.currentStop),
      etaMinutes: clearCurrent ? null : (etaMinutes ?? this.etaMinutes),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      telemetrySource: telemetrySource ?? this.telemetrySource,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'staffId': staffId,
        'name': name,
        'phone': phone,
        'email': email,
        'vehicleType': vehicleType,
        'vehicleReg': vehicleReg,
        'dutyStatus': dutyStatus.name,
        'rating': rating,
        'lat': lat,
        'lng': lng,
        'speedKmh': speedKmh,
        'battery': battery,
        'heading': heading,
        'currentOrderId': currentOrderId,
        'currentStop': currentStop,
        'etaMinutes': etaMinutes,
        'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
        'telemetrySource': telemetrySource,
      };

  factory Rider.fromMap(Map<String, dynamic> m) => Rider(
        id: m['id'] as String? ?? '',
        staffId: m['staffId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String? ?? '',
        vehicleType: m['vehicleType'] as String? ?? 'Bike',
        vehicleReg: m['vehicleReg'] as String? ?? '',
        dutyStatus: DutyStatus.parse(m['dutyStatus'] as String?),
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        speedKmh: (m['speedKmh'] as num?)?.toDouble(),
        battery: (m['battery'] as num?)?.toInt(),
        heading: (m['heading'] as num?)?.toDouble(),
        currentOrderId: m['currentOrderId'] as String?,
        currentStop: (m['currentStop'] as num?)?.toInt(),
        etaMinutes: (m['etaMinutes'] as num?)?.toInt(),
        lastUpdated: _dt(m['lastUpdated']),
        telemetrySource: m['telemetrySource'] as String? ?? 'none',
      );
}
