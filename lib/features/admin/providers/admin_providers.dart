import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/core.dart';
import '../../../core/data/data.dart';

/// Ek din ka data (chart ke liye).
class DailyTrendPoint {
  const DailyTrendPoint({
    required this.date,
    required this.created,
    required this.delivered,
  });

  final DateTime date;
  final int created;
  final int delivered;
}

/// Sirf admin user ke liye uid, warna null.
String? _adminUid(AppUser? user) =>
    (user != null && user.role == UserRole.admin) ? user.uid : null;

class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider(this._ordersRepo, this._ridersRepo, this._exceptionsRepo);

  final OrderRepository _ordersRepo;
  final RiderRepository _ridersRepo;
  final ExceptionRepository _exceptionsRepo;

  StreamSubscription? _ordersSub;
  StreamSubscription? _ridersSub;
  StreamSubscription? _exceptionsSub;
  String? _boundUid;

  List<DeliveryOrder> _orders = [];
  List<Rider> _riders = [];
  List<DeliveryException> _exceptions = [];
  bool _isLoading = true;
  String? _error;

  List<DeliveryOrder> get orders => _orders;
  List<Rider> get riders => _riders;
  List<DeliveryException> get exceptions => _exceptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Login / logout par streams dobara shuru hoti hain (naye token ke saath).
  void bind(AppUser? user) {
    final uid = _adminUid(user);
    if (uid == _boundUid) return;
    _boundUid = uid;
    _cancel();
    _orders = [];
    _riders = [];
    _exceptions = [];
    _error = null;
    _isLoading = true;
    if (uid != null) _start();
  }

  void _start() {
    _ordersSub = _ordersRepo.watchAllOrders().listen(
          (data) {
        _orders = data;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) => _onError('orders', e),
    );

    _ridersSub = _ridersRepo.watchRiders().listen(
          (data) {
        _riders = data;
        notifyListeners();
      },
      onError: (Object e) => _onError('riders', e),
    );

    _exceptionsSub = _exceptionsRepo.watchAll().listen(
          (data) {
        _exceptions = data;
        notifyListeners();
      },
      onError: (Object e) => _onError('exceptions', e),
    );
  }

  void _onError(String what, Object e) {
    debugPrint('[AdminDashboardProvider] $what stream error: $e');
    _error = '$what: $e';
    _isLoading = false;
    notifyListeners();
  }

  void _cancel() {
    _ordersSub?.cancel();
    _ridersSub?.cancel();
    _exceptionsSub?.cancel();
    _ordersSub = null;
    _ridersSub = null;
    _exceptionsSub = null;
  }

  int get totalOrders => _orders.length;
  int get activeFleet => _riders.where((r) => r.dutyStatus == DutyStatus.onDuty).length;
  int get pendingOrders => _orders.where((o) => o.status == OrderStatus.assigned || o.status == OrderStatus.unassigned).length;
  int get completedOrders => _orders.where((o) => o.status == OrderStatus.delivered).length;
  int get failedOrders => _orders.where((o) => o.status == OrderStatus.failed).length;
  int get unassignedOrders => _orders.where((o) => o.status == OrderStatus.unassigned).length;

  double get codCollected {
    return _orders
        .where((o) => o.status == OrderStatus.delivered && o.paymentType == PaymentType.cod)
        .fold(0.0, (sum, o) => sum + o.amount);
  }

  double get codInField {
    return _orders
        .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.failed && o.paymentType == PaymentType.cod)
        .fold(0.0, (sum, o) => sum + o.amount);
  }

  /// Delivered orders ki total value (COD + prepaid), real data.
  double get realizedVolume {
    return _orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold(0.0, (sum, o) => sum + o.amount);
  }

  double get slaSuccessRate {
    final completed = _orders.where((o) => o.status == OrderStatus.delivered).toList();
    if (completed.isEmpty) return 0.0;

    int onTimeCount = 0;
    for (final o in completed) {
      final deliveredAt = _deliveredAt(o);
      if (!deliveredAt.isAfter(o.windowEnd)) {
        onTimeCount++;
      }
    }
    return (onTimeCount / completed.length) * 100.0;
  }

  // ---------- Weekly trend (real data) ----------

  static DateTime _day(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  DateTime _deliveredAt(DeliveryOrder o) {
    return o.proof?.submittedAt ??
        o.history
            .firstWhere(
              (h) => h.status == OrderStatus.delivered,
          orElse: () => StatusEntry(status: OrderStatus.delivered, at: o.createdAt, byUid: ''),
        )
            .at;
  }

  /// Pichhle 7 din (purana -> aaj). Har din ke created aur delivered orders.
  List<DailyTrendPoint> get weeklyTrend {
    final today = _day(DateTime.now());
    return List.generate(7, (i) {
      final d = DateTime(today.year, today.month, today.day - (6 - i));
      final created = _orders.where((o) => _day(o.createdAt) == d).length;
      final delivered = _orders
          .where((o) => o.status == OrderStatus.delivered && _day(_deliveredAt(o)) == d)
          .length;
      return DailyTrendPoint(date: d, created: created, delivered: delivered);
    });
  }

  /// Pichhle 7 din mein bane orders ki tadaad.
  int get weekOrders => weeklyTrend.fold(0, (s, p) => s + p.created);

  /// Pichhle 7 din vs us se pehle ke 7 din (percent). Pichhla data na ho to null.
  double? get weekChangePercent {
    final today = _day(DateTime.now());
    final startThis = DateTime(today.year, today.month, today.day - 6);
    final startPrev = DateTime(today.year, today.month, today.day - 13);
    int cur = 0;
    int prev = 0;
    for (final o in _orders) {
      final d = _day(o.createdAt);
      if (!d.isBefore(startThis)) {
        cur++;
      } else if (!d.isBefore(startPrev)) {
        prev++;
      }
    }
    if (prev == 0) return null;
    return (cur - prev) / prev * 100.0;
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}

class AdminOrdersProvider extends ChangeNotifier {
  AdminOrdersProvider(this._ordersRepo, this._ridersRepo);

  final OrderRepository _ordersRepo;
  final RiderRepository _ridersRepo;

  StreamSubscription? _ordersSub;
  StreamSubscription? _ridersSub;
  String? _boundUid;

  List<DeliveryOrder> _orders = [];
  List<Rider> _riders = [];
  String _searchQuery = '';
  OrderStatus? _statusFilter;
  PaymentType? _paymentFilter;
  bool _isLoading = true;
  String? _error;

  List<DeliveryOrder> get orders {
    return _orders.where((o) {
      final matchesSearch = _searchQuery.isEmpty ||
          o.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == null || o.status == _statusFilter;
      final matchesPayment = _paymentFilter == null || o.paymentType == _paymentFilter;
      return matchesSearch && matchesStatus && matchesPayment;
    }).toList();
  }

  List<Rider> get riders => _riders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  OrderStatus? get statusFilter => _statusFilter;
  PaymentType? get paymentFilter => _paymentFilter;

  /// Login / logout par streams dobara shuru hoti hain.
  void bind(AppUser? user) {
    final uid = _adminUid(user);
    if (uid == _boundUid) return;
    _boundUid = uid;
    _cancel();
    _orders = [];
    _riders = [];
    _error = null;
    _isLoading = true;
    if (uid != null) _start();
  }

  /// Purani screens ke liye (ab zaroori nahi, bind() sab sambhalta hai).
  void init() {
    if (_ordersSub == null && _boundUid != null) _start();
  }

  void _start() {
    _ordersSub = _ordersRepo.watchAllOrders().listen(
          (data) {
        _orders = data;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[AdminOrdersProvider] orders stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
    _ridersSub = _ridersRepo.watchRiders().listen(
          (data) {
        _riders = data;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('[AdminOrdersProvider] riders stream error: $e'),
    );
  }

  void _cancel() {
    _ordersSub?.cancel();
    _ridersSub?.cancel();
    _ordersSub = null;
    _ridersSub = null;
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setStatusFilter(OrderStatus? s) {
    _statusFilter = s;
    notifyListeners();
  }

  void setPaymentFilter(PaymentType? p) {
    _paymentFilter = p;
    notifyListeners();
  }

  Future<void> createOrder(DeliveryOrder draft, String byUid) async {
    await _ordersRepo.createOrder(draft, byUid);
  }

  Future<void> assignRider(String orderId, String riderId, String byUid) async {
    await _ordersRepo.assignRider(orderId: orderId, riderId: riderId, byUid: byUid);
  }

  Future<void> cancelOrder(String orderId, String byUid, [String? reason]) async {
    await _ordersRepo.cancelOrder(orderId: orderId, byUid: byUid, reason: reason);
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}

class AdminExceptionsProvider extends ChangeNotifier {
  AdminExceptionsProvider(this._exceptionsRepo);

  final ExceptionRepository _exceptionsRepo;
  StreamSubscription? _sub;
  String? _boundUid;
  List<DeliveryException> _exceptions = [];
  bool _isLoading = true;
  String? _error;

  List<DeliveryException> get exceptions => _exceptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Login / logout par stream dobara shuru hoti hai.
  void bind(AppUser? user) {
    final uid = _adminUid(user);
    if (uid == _boundUid) return;
    _boundUid = uid;
    _sub?.cancel();
    _sub = null;
    _exceptions = [];
    _error = null;
    _isLoading = true;
    if (uid != null) _start();
  }

  /// Purani screens ke liye (ab zaroori nahi, bind() sab sambhalta hai).
  void init() {
    if (_sub == null && _boundUid != null) _start();
  }

  void _start() {
    _sub = _exceptionsRepo.watchAll().listen(
          (data) {
        _exceptions = data;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[AdminExceptionsProvider] exceptions stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> resolve({
    required String exceptionId,
    required ExceptionStatus outcome,
    required String byUid,
    String? note,
    String? newRiderId,
    DateTime? newStart,
    DateTime? newEnd,
  }) async {
    await _exceptionsRepo.resolve(
      exceptionId: exceptionId,
      outcome: outcome,
      byUid: byUid,
      note: note,
      newRiderId: newRiderId,
      newStart: newStart,
      newEnd: newEnd,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}