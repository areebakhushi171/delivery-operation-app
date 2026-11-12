import 'dart:async';

import '../../../../core/data/data.dart';
import '../../../../core/providers/base_provider.dart';
import '../../../../core/utils/utils.dart';

/// All rider-facing order state (home, list, map, history, details) comes from
/// this single stream, so every rider screen shows the same data.
class RiderOrdersProvider extends BaseProvider {
  RiderOrdersProvider(this._repo);

  final OrderRepository _repo;
  StreamSubscription<List<DeliveryOrder>>? _sub;
  String? _riderId;
  List<DeliveryOrder> _orders = const [];
  bool _loaded = false;
  String _query = '';
  RiderStatusFilter _filter = RiderStatusFilter.all;

  bool get isLoadingInitial => _riderId != null && !_loaded;
  String get query => _query;
  RiderStatusFilter get filter => _filter;

  void bind(AppUser? user) {
    final id = (user != null && user.role == UserRole.rider) ? user.uid : null;
    if (id == _riderId) return;
    _riderId = id;
    _subscribe();
    notifyLater();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = null;
    _orders = const [];
    _loaded = false;
    setError(null);
    final id = _riderId;
    if (id == null) return;
    _sub = _repo.watchRiderOrders(id).listen(
      (list) {
        _orders = list;
        _loaded = true;
        setError(null);
        notifyListeners();
      },
      onError: (Object _) {
        _loaded = true;
        setError('Could not load deliveries. Check your connection.');
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    _subscribe();
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setFilter(RiderStatusFilter f) {
    _filter = f;
    notifyListeners();
  }

  static int _byStop(DeliveryOrder a, DeliveryOrder b) {
    final c = (a.stopNumber ?? 9999).compareTo(b.stopNumber ?? 9999);
    return c != 0 ? c : a.windowStart.compareTo(b.windowStart);
  }

  DeliveryOrder? byId(String id) => _orders.where((o) => o.id == id).firstOrNull;

  /// Today's work: anything still active, plus today's closed deliveries.
  List<DeliveryOrder> get today {
    final now = DateTime.now();
    return _orders
        .where((o) => o.status.isActive || DateTimeUtils.isSameDay(o.windowStart, now))
        .toList()
      ..sort(_byStop);
  }

  int get total => today.length;
  int get completed => today.where((o) => o.status == OrderStatus.delivered).length;
  int get pending => today.where((o) => o.status.isActive).length;
  int get failed => today.where((o) => o.status == OrderStatus.failed).length;
  double get progress => total == 0 ? 0 : completed / total;

  List<DeliveryOrder> get active => today.where((o) => o.status.isActive).toList();

  /// Next stop: the delivery already out for delivery, else the lowest stop number.
  DeliveryOrder? get nextStop {
    final a = active;
    for (final o in a) {
      if (o.status == OrderStatus.outForDelivery) return o;
    }
    return a.isEmpty ? null : a.first;
  }

  List<DeliveryOrder> get upcoming => active.take(3).toList();

  List<DeliveryOrder> get filtered {
    final q = _query.trim().toLowerCase();
    return today.where((o) {
      if (!_filter.matches(o.status)) return false;
      if (q.isEmpty) return true;
      return o.id.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.address.toLowerCase().contains(q) ||
          o.area.toLowerCase().contains(q);
    }).toList();
  }

  DateTime _closedAt(DeliveryOrder o) => o.deliveredAt ?? o.failedAt ?? o.windowEnd;

  List<DeliveryOrder> history({
    required bool failedTab,
    required DateRangeOption range,
    String query = '',
  }) {
    final now = DateTime.now();
    final q = query.trim().toLowerCase();
    final want = failedTab ? OrderStatus.failed : OrderStatus.delivered;
    return _orders.where((o) {
      if (o.status != want) return false;
      if (!range.contains(_closedAt(o), now)) return false;
      return q.isEmpty ||
          o.id.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => _closedAt(b).compareTo(_closedAt(a)));
  }

  int codCollectedIn(Iterable<DeliveryOrder> list) =>
      list.where((o) => o.isCod && o.codCollected).fold(0, (s, o) => s + o.codAmount);

  int get codCollectedToday => codCollectedIn(today);
  int get codToCollect =>
      today.where((o) => o.isCod && o.status.isActive).fold(0, (s, o) => s + o.codAmount);

  /// Share of delivered orders that arrived inside their time window.
  double? get onTimeRate {
    final done = _orders.where((o) => o.status == OrderStatus.delivered).toList();
    if (done.isEmpty) return null;
    return done.where((o) => o.deliveredOnTime).length / done.length;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
