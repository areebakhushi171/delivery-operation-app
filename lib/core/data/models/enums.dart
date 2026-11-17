T parseEnum<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

enum UserRole {
  rider,
  admin;

  static UserRole parse(String? v) => parseEnum(values, v, UserRole.rider);
}

enum OrderStatus {
  unassigned('Unassigned'),
  assigned('Assigned'),
  pickedUp('Picked Up'),
  outForDelivery('Out for Delivery'),
  delivered('Delivered'),
  failed('Failed');

  const OrderStatus(this.label);
  final String label;

  bool get isActive =>
      this == OrderStatus.assigned ||
      this == OrderStatus.pickedUp ||
      this == OrderStatus.outForDelivery;
  bool get isClosed => this == OrderStatus.delivered || this == OrderStatus.failed;

  /// Next legal step in the rider workflow (null when none).
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.assigned:
        return OrderStatus.pickedUp;
      case OrderStatus.pickedUp:
        return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  bool canMoveTo(OrderStatus target) => next == target;

  static OrderStatus parse(String? v) => parseEnum(values, v, OrderStatus.unassigned);
}

enum RiderStatusFilter {
  all('All'),
  pending('Pending'),
  inTransit('In Transit'),
  delivered('Delivered'),
  failed('Failed');

  const RiderStatusFilter(this.label);
  final String label;

  bool matches(OrderStatus s) {
    switch (this) {
      case RiderStatusFilter.all:
        return true;
      case RiderStatusFilter.pending:
        return s == OrderStatus.assigned || s == OrderStatus.unassigned;
      case RiderStatusFilter.inTransit:
        return s == OrderStatus.pickedUp || s == OrderStatus.outForDelivery;
      case RiderStatusFilter.delivered:
        return s == OrderStatus.delivered;
      case RiderStatusFilter.failed:
        return s == OrderStatus.failed;
    }
  }
}

enum PaymentType {
  cod('COD'),
  prepaid('Prepaid');

  const PaymentType(this.label);
  final String label;
  static PaymentType parse(String? v) => parseEnum(values, v, PaymentType.prepaid);
}

enum ExceptionReason {
  customerNotAvailable('Customer Not Available'),
  wrongAddress('Wrong Address'),
  refusedDelivery('Refused Delivery'),
  damagedPackage('Damaged Package'),
  weatherTraffic('Weather / Traffic'),
  other('Other');

  const ExceptionReason(this.label);
  final String label;
  static ExceptionReason parse(String? v) => parseEnum(values, v, ExceptionReason.other);
}

enum ExceptionStatus {
  reported('Reported - Pending Triage'),
  rescheduled('Rescheduled'),
  reassigned('Reassigned'),
  rto('Returned to Origin'),
  resolved('Resolved');

  const ExceptionStatus(this.label);
  final String label;
  bool get isOpen => this == ExceptionStatus.reported;
  static ExceptionStatus parse(String? v) => parseEnum(values, v, ExceptionStatus.reported);
}

enum DutyStatus {
  onDuty('On Duty'),
  offDuty('Off Duty');

  const DutyStatus(this.label);
  final String label;
  static DutyStatus parse(String? v) => parseEnum(values, v, DutyStatus.offDuty);
}

enum NotificationType {
  assignment,
  routeChange,
  reminder,
  exceptionUpdate,
  announcement;

  static NotificationType parse(String? v) => parseEnum(values, v, NotificationType.announcement);
}

enum SyncState { pending, syncing, failed }
