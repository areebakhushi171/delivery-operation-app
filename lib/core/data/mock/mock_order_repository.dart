import '../../utils/utils.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_store.dart';

class MockOrderRepository implements OrderRepository {
  MockOrderRepository(this._s);
  final MockStore _s;

  @override
  Stream<List<DeliveryOrder>> watchAllOrders() => _s.orders.watch();

  @override
  Stream<List<DeliveryOrder>> watchActiveOrders() =>
      _s.orders.watch().map((l) => l.where((o) => o.status.isActive || o.status == OrderStatus.unassigned).toList());

  @override
  Stream<List<DeliveryOrder>> watchRiderOrders(String riderId) =>
      _s.orders.watch().map((l) => l.where((o) => o.riderId == riderId).toList());

  @override
  Future<List<DeliveryOrder>> fetchOrderHistory({
    int limit = 20,
    DeliveryOrder? startAfter,
  }) async {
    final list = _s.orders.watch().first;
    final all = await list;
    final closed = all.where((o) => o.status.isClosed).toList();
    closed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (startAfter != null) {
      final index = closed.indexWhere((o) => o.id == startAfter.id);
      if (index != -1 && index + 1 < closed.length) {
        return closed.skip(index + 1).take(limit).toList();
      }
      return [];
    }
    return closed.take(limit).toList();
  }

  @override
  Future<DeliveryOrder> createOrder(DeliveryOrder draft, String byUid) async {
    final now = DateTime.now();
    final order = draft.copyWith(
      id: _s.nextOrderId(),
      status: draft.riderId != null ? OrderStatus.assigned : OrderStatus.unassigned,
      createdAt: now,
      history: [
        StatusEntry(
          status: draft.riderId != null ? OrderStatus.assigned : OrderStatus.unassigned,
          at: now,
          byUid: byUid,
          note: draft.riderId != null ? 'Order created & assigned' : 'Order created',
        ),
      ],
    );
    _s.addOrder(order);
    if (draft.riderId != null) {
      _s.assignOrder(orderId: order.id, riderId: draft.riderId!, byUid: byUid);
    }
    _s.audit('order.create', byUid, order.id);
    _s.notify(
      to: 'admin',
      type: NotificationType.reminder,
      title: 'New order created',
      body: '${order.id} for ${order.customerName} needs a rider.',
      orderId: order.id,
    );
    return order;
  }

  @override
  Future<void> assignRider({
    required String orderId,
    required String riderId,
    required String byUid,
  }) async =>
      _s.assignOrder(orderId: orderId, riderId: riderId, byUid: byUid);

  @override
  Future<void> updateStatus({
    required String orderId,
    required OrderStatus next,
    required String byUid,
  }) async {
    final o = _s.requireOrder(orderId);
    if (o.riderId != byUid) throw const AppException('This delivery is not assigned to you.');
    if (o.status == next) return; // idempotent (safe for offline replays)
    if (next == OrderStatus.delivered) {
      throw const AppException('Complete delivery with photo proof of delivery.');
    }
    if (!o.status.canMoveTo(next)) {
      throw AppException('Cannot move from ${o.status.label} to ${next.label}.');
    }
    _s.putOrder(
      o.copyWith(
        status: next,
        history: [...o.history, StatusEntry(status: next, at: DateTime.now(), byUid: byUid)],
      ),
    );
    _s.refreshRider(byUid);
    _s.audit('order.status', byUid, orderId, {'to': next.name});
  }

  @override
  Future<void> submitProof({required DeliveryProof proof, required String byUid}) async {
    final o = _s.requireOrder(proof.orderId);
    if (o.riderId != byUid) throw const AppException('This delivery is not assigned to you.');
    if (o.status == OrderStatus.delivered) return; // idempotent
    if (o.status != OrderStatus.outForDelivery) {
      throw const AppException('Order must be Out for Delivery before proof can be submitted.');
    }
    if (proof.photoPath.isEmpty) throw const AppException('A delivery photo is required.');
    if (o.isCod && !proof.codAcknowledged) {
      throw const AppException('Please confirm the COD amount was collected.');
    }
    final now = DateTime.now();
    _s.putOrder(
      o.copyWith(
        status: OrderStatus.delivered,
        proof: proof,
        codCollected: o.isCod,
        history: [...o.history, StatusEntry(status: OrderStatus.delivered, at: now, byUid: byUid)],
      ),
    );
    _s.refreshRider(byUid);
    _s.notify(
      to: 'admin',
      type: NotificationType.announcement,
      title: 'Delivered',
      body: '${o.id} delivered to ${proof.recipientName}.',
      orderId: o.id,
    );
    _s.audit('order.delivered', byUid, o.id, {'cod': o.isCod ? o.codAmount : 0});
  }

  @override
  Future<void> reschedule({
    required String orderId,
    required DateTime start,
    required DateTime end,
    required String byUid,
  }) async =>
      _s.rescheduleOrder(orderId: orderId, start: start, end: end, byUid: byUid);

  @override
  Future<void> cancelOrder({
    required String orderId,
    required String byUid,
    String? reason,
  }) async {
    final o = _s.requireOrder(orderId);
    if (o.status == OrderStatus.delivered) {
      throw const AppException('Delivered orders cannot be cancelled.');
    }
    final now = DateTime.now();
    _s.putOrder(
      o.copyWith(
        status: OrderStatus.failed,
        history: [
          ...o.history,
          StatusEntry(status: OrderStatus.failed, at: now, byUid: byUid, note: reason ?? 'Cancelled by Admin'),
        ],
      ),
    );
    if (o.riderId != null) {
      _s.refreshRider(o.riderId!);
    }
    _s.audit('order.cancel', byUid, orderId, {'reason': reason});
  }

  @override
  Future<void> reconcileCod({required String orderId, required String byUid}) async {
    final o = _s.requireOrder(orderId);
    if (!o.isCod || !o.codCollected) throw const AppException('No collected COD to reconcile.');
    if (o.codDeposited) return;
    _s.putOrder(o.copyWith(codDeposited: true));
    _s.audit('cod.reconcile', byUid, orderId, {'amount': o.codAmount});
  }
}
