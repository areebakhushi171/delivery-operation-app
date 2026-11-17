import '../../../../core/data/data.dart';
import '../../../../core/providers/base_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../core/utils/utils.dart';

/// done   = confirmed by the backend.
/// queued = only stored on the phone (offline) - NOT completed yet.
enum ActionOutcome { done, queued }

class RiderActionsProvider extends BaseProvider {
  RiderActionsProvider({required this.orders, required this.exceptions, required this.sync}) {
    sync.registerHandler('status', _runStatus);
    sync.registerHandler('proof', _runProof);
    sync.registerHandler('exception', _runException);
  }

  final OrderRepository orders;
  final ExceptionRepository exceptions;
  final SyncProvider sync;
  AppUser? _user;

  void bind(AppUser? user) => _user = user;

  String get _uid => _user?.uid ?? (throw const AppException('You are signed out.'));

  Future<ActionOutcome?> advanceStatus(DeliveryOrder order) => guard(() async {
        final next = order.status.next;
        if (next == null) throw const AppException('No further status steps for this order.');
        if (next == OrderStatus.delivered) {
          throw const AppException('Complete delivery with photo proof of delivery.');
        }
        final payload = {'orderId': order.id, 'next': next.name, 'byUid': _uid};
        if (!sync.isOnline) {
          await sync.enqueue('status', payload);
          return ActionOutcome.queued;
        }
        await _runStatus(payload);
        return ActionOutcome.done;
      });

  Future<ActionOutcome?> submitProof(DeliveryProof proof) => guard(() async {
        final payload = {...proof.toMap(), 'byUid': _uid};
        if (!sync.isOnline) {
          await sync.enqueue('proof', payload);
          return ActionOutcome.queued;
        }
        await _runProof(payload);
        return ActionOutcome.done;
      });

  Future<ActionOutcome?> reportException(DeliveryException ex) => guard(() async {
        final payload = {...ex.toMap(), 'byUid': _uid};
        if (!sync.isOnline) {
          await sync.enqueue('exception', payload);
          return ActionOutcome.queued;
        }
        await _runException(payload);
        return ActionOutcome.done;
      });

  Future<void> _runStatus(Map<String, dynamic> p) => orders.updateStatus(
        orderId: p['orderId'] as String,
        next: OrderStatus.parse(p['next'] as String?),
        byUid: p['byUid'] as String,
      );

  Future<void> _runProof(Map<String, dynamic> p) =>
      orders.submitProof(proof: DeliveryProof.fromMap(p), byUid: p['byUid'] as String);

  Future<void> _runException(Map<String, dynamic> p) =>
      exceptions.report(DeliveryException.fromMap(p), p['byUid'] as String);
}
